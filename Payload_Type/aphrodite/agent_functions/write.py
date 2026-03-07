from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class WriteArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="path",
                type=ParameterType.String,
                description="Destination file path",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=0, required=True)],
            ),
            CommandParameter(
                name="content",
                type=ParameterType.String,
                description="Content to write",
                default_value="",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=1, required=False)],
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line) == 0:
            raise ValueError("path required")
        if self.command_line.strip()[0] == '{':
            self.load_args_from_json_string(self.command_line)
        else:
            parts = self.command_line.strip().split(None, 1)
            self.add_arg("path", parts[0])
            self.add_arg("content", parts[1] if len(parts) > 1 else "")


class WriteCommand(CommandBase):
    cmd = "write"
    needs_admin = False
    help_cmd = "write <path> [content]"
    description = "Write content to a file on the target"
    version = 1
    author = "@0xbbuddha"
    argument_class = WriteArguments
    attackmapping = ["T1105", "T1074"]
    attributes = CommandAttributes(supported_os=[SupportedOS.Linux, SupportedOS.Windows])

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = task.args.get_arg("path")
        return task

    async def process_response(self, response: AgentResponse):
        pass
