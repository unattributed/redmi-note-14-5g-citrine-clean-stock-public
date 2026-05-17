#!/usr/bin/env python3
"""
Decode enough Android binary XML to inspect AndroidManifest.xml.

This helper is intentionally self-contained so the project can inspect a
system APK manifest without depending on apktool, jadx, aapt, or network
package installation.
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

RES_STRING_POOL_TYPE = 0x0001
RES_XML_TYPE = 0x0003
RES_XML_RESOURCE_MAP_TYPE = 0x0180
RES_XML_START_NAMESPACE_TYPE = 0x0100
RES_XML_END_NAMESPACE_TYPE = 0x0101
RES_XML_START_ELEMENT_TYPE = 0x0102
RES_XML_END_ELEMENT_TYPE = 0x0103
RES_XML_CDATA_TYPE = 0x0104

UTF8_FLAG = 0x00000100
NO_INDEX = 0xFFFFFFFF

TYPE_NULL = 0x00
TYPE_REFERENCE = 0x01
TYPE_ATTRIBUTE = 0x02
TYPE_STRING = 0x03
TYPE_FLOAT = 0x04
TYPE_DIMENSION = 0x05
TYPE_FRACTION = 0x06
TYPE_FIRST_INT = 0x10
TYPE_INT_DEC = 0x10
TYPE_INT_HEX = 0x11
TYPE_INT_BOOLEAN = 0x12
TYPE_FIRST_COLOR_INT = 0x1C
TYPE_LAST_COLOR_INT = 0x1F
TYPE_LAST_INT = 0x1F

ANDROID_NS = "http://schemas.android.com/apk/res/android"


def u16(data: bytes, offset: int) -> int:
    return struct.unpack_from("<H", data, offset)[0]


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def idx(value: int) -> Optional[int]:
    if value == NO_INDEX:
        return None
    return value


def decode_length8(data: bytes, offset: int) -> Tuple[int, int]:
    first = data[offset]
    if first & 0x80:
        second = data[offset + 1]
        return ((first & 0x7F) << 8) | second, 2
    return first, 1


def decode_length16(data: bytes, offset: int) -> Tuple[int, int]:
    first = u16(data, offset)
    if first & 0x8000:
        second = u16(data, offset + 2)
        return ((first & 0x7FFF) << 16) | second, 4
    return first, 2


class StringPool:
    def __init__(self, strings: List[str]) -> None:
        self.strings = strings

    def get(self, index: Optional[int]) -> str:
        if index is None:
            return ""
        if index < 0 or index >= len(self.strings):
            return f"<bad_string_index_{index}>"
        return self.strings[index]

    @classmethod
    def parse(cls, data: bytes, offset: int) -> Tuple["StringPool", int]:
        chunk_type = u16(data, offset)
        header_size = u16(data, offset + 2)
        chunk_size = u32(data, offset + 4)
        if chunk_type != RES_STRING_POOL_TYPE:
            raise ValueError(f"expected string pool at {offset}, got chunk type 0x{chunk_type:04x}")

        string_count = u32(data, offset + 8)
        style_count = u32(data, offset + 12)
        flags = u32(data, offset + 16)
        strings_start = u32(data, offset + 20)
        styles_start = u32(data, offset + 24)
        is_utf8 = bool(flags & UTF8_FLAG)

        offsets_base = offset + header_size
        string_offsets = [u32(data, offsets_base + i * 4) for i in range(string_count)]
        strings_base = offset + strings_start

        strings: List[str] = []
        for string_offset in string_offsets:
            string_pos = strings_base + string_offset
            if is_utf8:
                _, consumed_1 = decode_length8(data, string_pos)
                byte_len, consumed_2 = decode_length8(data, string_pos + consumed_1)
                raw_start = string_pos + consumed_1 + consumed_2
                raw = data[raw_start:raw_start + byte_len]
                strings.append(raw.decode("utf-8", errors="replace"))
            else:
                char_len, consumed = decode_length16(data, string_pos)
                raw_start = string_pos + consumed
                raw = data[raw_start:raw_start + char_len * 2]
                strings.append(raw.decode("utf-16le", errors="replace"))

        _ = style_count
        _ = styles_start
        return cls(strings), offset + chunk_size


def typed_value_to_python(data_type: int, data_value: int, raw_value: str, strings: StringPool) -> Any:
    if data_type == TYPE_STRING:
        return raw_value
    if data_type == TYPE_INT_BOOLEAN:
        return bool(data_value)
    if data_type == TYPE_INT_DEC:
        if data_value & 0x80000000:
            return -((~data_value & 0xFFFFFFFF) + 1)
        return data_value
    if data_type == TYPE_INT_HEX:
        return f"0x{data_value:08x}"
    if data_type == TYPE_REFERENCE:
        return f"@0x{data_value:08x}"
    if data_type == TYPE_ATTRIBUTE:
        return f"?0x{data_value:08x}"
    if TYPE_FIRST_COLOR_INT <= data_type <= TYPE_LAST_COLOR_INT:
        return f"#{data_value:08x}"
    if TYPE_FIRST_INT <= data_type <= TYPE_LAST_INT:
        return data_value
    if raw_value:
        return raw_value
    return f"type=0x{data_type:02x},data=0x{data_value:08x}"


def effective_component_name(package_name: str, name: str) -> str:
    if not name:
        return name
    if name.startswith("."):
        return package_name + name
    if "." not in name:
        return package_name + "." + name
    return name


def attr_value(attrs: Dict[str, Any], key: str) -> Any:
    if key in attrs:
        return attrs[key]
    android_key = f"android:{key}"
    if android_key in attrs:
        return attrs[android_key]
    return None


def stringify(value: Any) -> str:
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return ""
    return str(value)


def parse_axml(data: bytes) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    if len(data) < 8:
        raise ValueError("file too small")

    root_type = u16(data, 0)
    root_size = u32(data, 4)
    if root_type != RES_XML_TYPE:
        raise ValueError(f"not Android binary XML, root chunk type 0x{root_type:04x}")

    offset = 8
    strings: Optional[StringPool] = None
    resource_map: List[int] = []
    events: List[Dict[str, Any]] = []

    package_name = ""
    uses_permissions: List[str] = []
    components: List[Dict[str, Any]] = []
    current_component: Optional[Dict[str, Any]] = None
    current_filter: Optional[Dict[str, Any]] = None

    while offset + 8 <= min(len(data), root_size):
        chunk_type = u16(data, offset)
        header_size = u16(data, offset + 2)
        chunk_size = u32(data, offset + 4)
        if chunk_size <= 0:
            raise ValueError(f"invalid chunk size {chunk_size} at {offset}")

        if chunk_type == RES_STRING_POOL_TYPE:
            strings, next_offset = StringPool.parse(data, offset)
            offset = next_offset
            continue

        if strings is None:
            offset += chunk_size
            continue

        if chunk_type == RES_XML_RESOURCE_MAP_TYPE:
            count = (chunk_size - header_size) // 4
            resource_map = [u32(data, offset + header_size + i * 4) for i in range(count)]
            offset += chunk_size
            continue

        if chunk_type == RES_XML_START_ELEMENT_TYPE:
            line_number = u32(data, offset + 8)
            ns = idx(u32(data, offset + 16))
            name_idx = idx(u32(data, offset + 20))
            tag_name = strings.get(name_idx)
            attr_start = u16(data, offset + 24)
            attr_size = u16(data, offset + 26)
            attr_count = u16(data, offset + 28)
            attrs: Dict[str, Any] = {}
            attr_details: List[Dict[str, Any]] = []
            attr_base = offset + attr_start

            for i in range(attr_count):
                item = attr_base + i * attr_size
                attr_ns_idx = idx(u32(data, item + 0))
                attr_name_idx = idx(u32(data, item + 4))
                raw_idx = idx(u32(data, item + 8))
                data_type = data[item + 15]
                data_value = u32(data, item + 16)

                attr_ns = strings.get(attr_ns_idx)
                attr_local = strings.get(attr_name_idx)
                raw_value = strings.get(raw_idx)
                prefix = "android" if attr_ns == ANDROID_NS else ""
                attr_key = f"{prefix}:{attr_local}" if prefix else attr_local
                value = typed_value_to_python(data_type, data_value, raw_value, strings)
                attrs[attr_key] = value
                attr_details.append(
                    {
                        "name": attr_key,
                        "local_name": attr_local,
                        "namespace": attr_ns,
                        "type": f"0x{data_type:02x}",
                        "value": value,
                    }
                )

            event = {
                "event": "start",
                "line": line_number,
                "tag": tag_name,
                "namespace": strings.get(ns),
                "attrs": attrs,
                "attr_details": attr_details,
            }
            events.append(event)

            if tag_name == "manifest":
                package_name = stringify(attr_value(attrs, "package"))

            if tag_name == "uses-permission":
                permission_name = stringify(attr_value(attrs, "name"))
                if permission_name:
                    uses_permissions.append(permission_name)

            if tag_name in {"activity", "activity-alias", "service", "receiver", "provider"}:
                component_name = stringify(attr_value(attrs, "name"))
                current_component = {
                    "type": tag_name,
                    "name_raw": component_name,
                    "name": effective_component_name(package_name, component_name),
                    "exported": attr_value(attrs, "exported"),
                    "enabled": attr_value(attrs, "enabled"),
                    "permission": attr_value(attrs, "permission"),
                    "authorities": attr_value(attrs, "authorities"),
                    "process": attr_value(attrs, "process"),
                    "directBootAware": attr_value(attrs, "directBootAware"),
                    "intent_filters": [],
                    "attributes": {key: stringify(value) for key, value in attrs.items()},
                }
                components.append(current_component)

            elif tag_name == "intent-filter" and current_component is not None:
                current_filter = {
                    "actions": [],
                    "categories": [],
                    "data": [],
                    "attributes": {key: stringify(value) for key, value in attrs.items()},
                }
                current_component["intent_filters"].append(current_filter)

            elif tag_name == "action" and current_filter is not None:
                action_name = stringify(attr_value(attrs, "name"))
                if action_name:
                    current_filter["actions"].append(action_name)

            elif tag_name == "category" and current_filter is not None:
                category_name = stringify(attr_value(attrs, "name"))
                if category_name:
                    current_filter["categories"].append(category_name)

            elif tag_name == "data" and current_filter is not None:
                current_filter["data"].append({key: stringify(value) for key, value in attrs.items()})

        elif chunk_type == RES_XML_END_ELEMENT_TYPE:
            line_number = u32(data, offset + 8)
            name_idx = idx(u32(data, offset + 20))
            tag_name = strings.get(name_idx)
            events.append({"event": "end", "line": line_number, "tag": tag_name})
            if tag_name == "intent-filter":
                current_filter = None
            if current_component is not None and tag_name == current_component.get("type"):
                current_component = None

        elif chunk_type in {RES_XML_START_NAMESPACE_TYPE, RES_XML_END_NAMESPACE_TYPE, RES_XML_CDATA_TYPE}:
            pass

        offset += chunk_size

    summary = {
        "package": package_name,
        "uses_permissions": sorted(set(uses_permissions)),
        "components": components,
        "resource_map_count": len(resource_map),
    }
    return events, summary


def write_xmlish(events: List[Dict[str, Any]], output: Path) -> None:
    indent = 0
    lines: List[str] = []
    for event in events:
        tag = event.get("tag", "")
        if event.get("event") == "end":
            indent = max(0, indent - 1)
            lines.append("  " * indent + f"</{tag}>")
        elif event.get("event") == "start":
            attrs = event.get("attrs", {})
            if attrs:
                rendered = " ".join(f'{key}="{stringify(value)}"' for key, value in sorted(attrs.items()))
                lines.append("  " * indent + f"<{tag} {rendered}>")
            else:
                lines.append("  " * indent + f"<{tag}>")
            indent += 1
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_components_tsv(summary: Dict[str, Any], output: Path) -> None:
    lines = ["type\tname\texported\tenabled\tpermission\tactions\tcategories\tdata"]
    for component in summary.get("components", []):
        actions: List[str] = []
        categories: List[str] = []
        data_items: List[str] = []
        for filt in component.get("intent_filters", []):
            actions.extend(filt.get("actions", []))
            categories.extend(filt.get("categories", []))
            for data in filt.get("data", []):
                data_items.append(",".join(f"{k}={v}" for k, v in sorted(data.items())))
        lines.append(
            "\t".join(
                [
                    stringify(component.get("type")),
                    stringify(component.get("name")),
                    stringify(component.get("exported")),
                    stringify(component.get("enabled")),
                    stringify(component.get("permission")),
                    "|".join(sorted(set(actions))),
                    "|".join(sorted(set(categories))),
                    "|".join(data_items),
                ]
            )
        )
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_verification_report(summary: Dict[str, Any], output: Path) -> None:
    lines: List[str] = []
    package_name = summary.get("package", "")
    lines.append(f"package: {package_name}")
    lines.append("")

    matches = [
        item for item in summary.get("components", [])
        if "VerificationActivity" in stringify(item.get("name"))
    ]

    if not matches:
        lines.append("VerificationActivity: not found")
    for item in matches:
        lines.append(f"component: {item.get('name')}")
        lines.append(f"type: {item.get('type')}")
        lines.append(f"exported: {stringify(item.get('exported'))}")
        lines.append(f"enabled: {stringify(item.get('enabled'))}")
        lines.append(f"permission: {stringify(item.get('permission'))}")
        lines.append(f"process: {stringify(item.get('process'))}")
        lines.append("intent_filters:")
        for idx, filt in enumerate(item.get("intent_filters", []), start=1):
            lines.append(f"  filter {idx}:")
            lines.append(f"    actions: {', '.join(filt.get('actions', []))}")
            lines.append(f"    categories: {', '.join(filt.get('categories', []))}")
            if filt.get("data"):
                lines.append("    data:")
                for data in filt.get("data", []):
                    lines.append("      " + ", ".join(f"{k}={v}" for k, v in sorted(data.items())))
            else:
                lines.append("    data: none")
        lines.append("")

    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Decode AndroidManifest.xml from binary AXML")
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--json", type=Path, required=True)
    parser.add_argument("--xmlish", type=Path, required=True)
    parser.add_argument("--components", type=Path, required=True)
    parser.add_argument("--verification", type=Path, required=True)
    args = parser.parse_args()

    data = args.manifest.read_bytes()
    events, summary = parse_axml(data)

    args.json.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_xmlish(events, args.xmlish)
    write_components_tsv(summary, args.components)
    write_verification_report(summary, args.verification)

    print(f"package: {summary.get('package')}")
    print(f"components: {len(summary.get('components', []))}")
    print(f"uses_permissions: {len(summary.get('uses_permissions', []))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
