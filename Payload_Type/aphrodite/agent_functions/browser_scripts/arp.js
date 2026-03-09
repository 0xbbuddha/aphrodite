function(task, responses) {
    if (task.status.includes("error")) {
        return {'plaintext': responses.reduce((p, c) => p + c, "")};
    } else if (responses.length > 0) {
        let rows = [];
        const headers = [
            {"plaintext": "IP",        "type": "string", "cellStyle": {}},
            {"plaintext": "MAC",       "type": "string", "cellStyle": {}},
            {"plaintext": "Interface", "type": "string", "cellStyle": {}},
            {"plaintext": "State",     "type": "string", "cellStyle": {}},
        ];
        for (let i = 0; i < responses.length; i++) {
            let data;
            try { data = JSON.parse(responses[i]); }
            catch (e) { return {'plaintext': responses.reduce((p, c) => p + c, "")}; }
            const entries = data["entries"] || [];
            for (const e of entries) {
                rows.push({
                    "rowStyle": {},
                    "IP":        {"plaintext": e["ip"]    || "", "cellStyle": {}},
                    "MAC":       {"plaintext": e["mac"]   || "", "cellStyle": {}},
                    "Interface": {"plaintext": e["iface"] || "", "cellStyle": {}},
                    "State":     {"plaintext": e["state"] || "", "cellStyle": {}},
                });
            }
        }
        return {"table": [{"headers": headers, "rows": rows, "title": "ARP Table"}]};
    } else {
        return {"plaintext": "No output."};
    }
}
