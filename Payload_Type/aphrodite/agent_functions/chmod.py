from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class ChmodArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="path",
                type=ParameterType.String,
                description="File or directory path",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=0, required=True)],
            ),
            CommandParameter(
                name="mode",
                type=ParameterType.String,
                description="Permission mode (e.g. 755, +x, u+rw)",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=1, required=True)],
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line) == 0:
            raise ValueError("path and mode required")
        if self.command_line.strip()[0] == '{':
            self.load_args_from_json_string(self.command_line)
        else:
            parts = self.command_line.strip().split(None, 1)
            if len(parts) < 2:
                raise ValueError("Usage: chmod <mode> <path>")
            self.add_arg("mode", parts[0])
            self.add_arg("path", parts[1])


class ChmodCommand(CommandBase):
    cmd = "chmod"
    needs_admin = False
    help_cmd = "chmod <mode> <path>"
    description = "Change file permissions (Linux only)"
    version = 1
    author = "@0xbbuddha"
    argument_class = ChmodArguments
    attackmapping = ["T1222.002"]
    attributes = CommandAttributes(supported_os=[SupportedOS.Linux])

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = "{} {}".format(task.args.get_arg("mode"), task.args.get_arg("path"))
        return task

    async def process_response(self, response: AgentResponse):
        pass
