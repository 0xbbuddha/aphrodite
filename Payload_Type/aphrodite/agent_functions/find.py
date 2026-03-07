from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class FindArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="path",
                type=ParameterType.String,
                description="Root directory to search",
                default_value=".",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=0, required=False)],
            ),
            CommandParameter(
                name="pattern",
                type=ParameterType.String,
                description="Filename substring to match (empty = all files)",
                default_value="",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=1, required=False)],
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line) == 0:
            self.add_arg("path", ".")
            self.add_arg("pattern", "")
        elif self.command_line.strip()[0] == '{':
            self.load_args_from_json_string(self.command_line)
        else:
            parts = self.command_line.strip().split(None, 1)
            self.add_arg("path", parts[0])
            self.add_arg("pattern", parts[1] if len(parts) > 1 else "")


class FindCommand(CommandBase):
    cmd = "find"
    needs_admin = False
    help_cmd = "find [path] [pattern]"
    description = "Recursively find files matching a name pattern"
    version = 1
    author = "@0xbbuddha"
    argument_class = FindArguments
    attackmapping = ["T1083"]
    attributes = CommandAttributes(supported_os=[SupportedOS.Linux, SupportedOS.Windows])

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = "{} {}".format(task.args.get_arg("path"), task.args.get_arg("pattern")).strip()
        return task

    async def process_response(self, response: AgentResponse):
        pass
