function(task, responses) {
    if (task.status.includes("error")) {
        return {'plaintext': responses.reduce((p, c) => p + c, "")};
    } else if (responses.length > 0) {
        let rows = [];
        const headers = [
            {"plaintext": "Filesystem", "type": "string", "cellStyle": {"fillWidth": true}},
            {"plaintext": "Size",       "type": "string", "cellStyle": {}},
            {"plaintext": "Used",       "type": "string", "cellStyle": {}},
            {"plaintext": "Avail",      "type": "string", "cellStyle": {}},
            {"plaintext": "Use%",       "type": "string", "cellStyle": {}},
            {"plaintext": "Mounted on", "type": "string", "cellStyle": {"fillWidth": true}},
        ];
        for (let i = 0; i < responses.length; i++) {
            let data;
            try { data = JSON.parse(responses[i]); }
            catch (e) { return {'plaintext': responses.reduce((p, c) => p + c, "")}; }
            const drives = data["drives"] || [];
            for (const d of drives) {
                rows.push({
                    "rowStyle": {},
                    "Filesystem": {"plaintext": d["filesystem"] || "", "cellStyle": {"fillWidth": true}},
                    "Size":       {"plaintext": d["size"]       || "", "cellStyle": {}},
                    "Used":       {"plaintext": d["used"]       || "", "cellStyle": {}},
                    "Avail":      {"plaintext": d["avail"]      || "", "cellStyle": {}},
                    "Use%":       {"plaintext": d["use_pct"]    || "", "cellStyle": {}},
                    "Mounted on": {"plaintext": d["mount"]      || "", "cellStyle": {"fillWidth": true}},
                });
            }
        }
        return {"table": [{"headers": headers, "rows": rows, "title": "Disk Usage"}]};
    } else {
        return {"plaintext": "No output."};
    }
}
