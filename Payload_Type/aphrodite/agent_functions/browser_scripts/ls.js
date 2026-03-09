function(task, responses) {
    if (task.status.includes("error")) {
        const combined = responses.reduce((prev, cur) => prev + cur, "");
        return {'plaintext': combined};
    } else if (responses.length > 0) {
        let rows = [];
        const headers = [
            {"plaintext": "Name",     "type": "string", "cellStyle": {"fillWidth": true}},
            {"plaintext": "Type",     "type": "string", "cellStyle": {}},
            {"plaintext": "Size",     "type": "size",   "cellStyle": {}},
            {"plaintext": "Modified", "type": "date",   "cellStyle": {}},
            {"plaintext": "Perms",    "type": "string", "cellStyle": {}},
        ];

        for (let i = 0; i < responses.length; i++) {
            let data;
            try {
                data = JSON.parse(responses[i]);
            } catch (e) {
                return {'plaintext': responses.reduce((p, c) => p + c, "")};
            }

            const files = data["file_browser"] ? data["file_browser"]["files"] : data;
            if (!files) continue;

            for (let j = 0; j < files.length; j++) {
                const f = files[j];
                const modTime = f["modify_time"]
                    ? new Date(f["modify_time"] * 1000).toISOString().replace("T", " ").slice(0, 16)
                    : "";
                const perms = f["permissions"] ? (f["permissions"]["permissions"] || "") : "";
                rows.push({
                    "rowStyle": {},
                    "Name":     {"plaintext": f["name"] || "", "cellStyle": {"fillWidth": true}},
                    "Type":     {"plaintext": f["is_file"] ? "file" : "dir", "cellStyle": {}},
                    "Size":     {"plaintext": f["is_file"] ? String(f["size"] || 0) : "", "cellStyle": {}},
                    "Modified": {"plaintext": modTime, "cellStyle": {}},
                    "Perms":    {"plaintext": perms, "cellStyle": {}},
                });
            }
        }

        return {"table": [{"headers": headers, "rows": rows, "title": "Directory Listing"}]};
    } else {
        return {"plaintext": "No output."};
    }
}
