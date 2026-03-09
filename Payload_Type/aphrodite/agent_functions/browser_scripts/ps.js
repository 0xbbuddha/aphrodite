function(task, responses) {
    if (task.status.includes("error")) {
        const combined = responses.reduce((prev, cur) => prev + cur, "");
        return {'plaintext': combined};
    } else if (responses.length > 0) {
        let rows = [];
        const headers = [
            {"plaintext": "PID",     "type": "number", "cellStyle": {}},
            {"plaintext": "PPID",    "type": "number", "cellStyle": {}},
            {"plaintext": "Name",    "type": "string", "cellStyle": {"fillWidth": true}},
            {"plaintext": "User",    "type": "string", "cellStyle": {}},
            {"plaintext": "Arch",    "type": "string", "cellStyle": {}},
            {"plaintext": "Command", "type": "string", "cellStyle": {"fillWidth": true}},
        ];

        for (let i = 0; i < responses.length; i++) {
            let data;
            try {
                data = JSON.parse(responses[i]);
            } catch (e) {
                return {'plaintext': responses.reduce((p, c) => p + c, "")};
            }

            const procs = data["processes"] ? data["processes"] : data;
            if (!procs) continue;

            for (let j = 0; j < procs.length; j++) {
                const p = procs[j];
                rows.push({
                    "rowStyle": {},
                    "PID":     {"plaintext": String(p["process_id"] || ""), "cellStyle": {}},
                    "PPID":    {"plaintext": String(p["parent_process_id"] || ""), "cellStyle": {}},
                    "Name":    {"plaintext": p["name"] || "", "cellStyle": {"fillWidth": true}},
                    "User":    {"plaintext": p["user"] || "", "cellStyle": {}},
                    "Arch":    {"plaintext": p["architecture"] || "", "cellStyle": {}},
                    "Command": {"plaintext": p["command_line"] || "", "cellStyle": {"fillWidth": true}},
                });
            }
        }

        return {"table": [{"headers": headers, "rows": rows, "title": "Process List"}]};
    } else {
        return {"plaintext": "No output."};
    }
}
