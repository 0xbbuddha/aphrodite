function(task, responses) {
    if (task.status.includes("error")) {
        return {'plaintext': responses.reduce((p, c) => p + c, "")};
    } else if (responses.length > 0) {
        let rows = [];
        const headers = [
            {"plaintext": "Key",   "type": "string", "cellStyle": {}},
            {"plaintext": "Value", "type": "string", "cellStyle": {"fillWidth": true}},
        ];
        for (let i = 0; i < responses.length; i++) {
            let data;
            try { data = JSON.parse(responses[i]); }
            catch (e) { return {'plaintext': responses.reduce((p, c) => p + c, "")}; }
            const env = data["env"] || [];
            for (const e of env) {
                rows.push({
                    "rowStyle": {},
                    "Key":   {"plaintext": e["key"]   || "", "cellStyle": {}},
                    "Value": {"plaintext": e["value"] || "", "cellStyle": {"fillWidth": true}},
                });
            }
        }
        return {"table": [{"headers": headers, "rows": rows, "title": "Environment Variables"}]};
    } else {
        return {"plaintext": "No output."};
    }
}
