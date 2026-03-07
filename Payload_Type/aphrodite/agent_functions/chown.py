from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class ChownArguments(TaskArguments):
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
                name="owner",
                type=ParameterType.String,
                description="New owner (user or user:group)",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=1, required=True)],
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line) == 0:
            raise ValueError("path and owner required")
        if self.command_line.strip()[0] == '{':
            self.load_args_from_json_string(self.command_line)
        else:
            parts = self.command_line.strip().split(None, 1)
            if len(parts) < 2:
                raise ValueError("Usage: chown <owner> <path>")
            self.add_arg("owner", parts[0])
            self.add_arg("path", parts[1])


class ChownCommand(CommandBase):
    cmd = "chown"
    needs_admin = False
    help_cmd = "chown <owner> <path>"
    description = "Change file owner (Linux only)"
    version = 1
    author = "@0xbbuddha"
    argument_class = ChownArguments
    attackmapping = ["T1222.002"]
    attributes = CommandAttributes(supported_os=[SupportedOS.Linux])

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = "{} {}".format(task.args.get_arg("owner"), task.args.get_arg("path"))
        return task

    async def process_response(self, response: AgentResponse):
        pass
