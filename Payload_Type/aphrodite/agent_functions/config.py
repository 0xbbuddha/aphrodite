from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class ConfigArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="sleep",
                type=ParameterType.String,
                description="New sleep interval in seconds (leave empty to keep current)",
                default_value="",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=0, required=False)],
            ),
            CommandParameter(
                name="jitter",
                type=ParameterType.String,
                description="New jitter percentage 0-100 (leave empty to keep current)",
                default_value="",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=1, required=False)],
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line.strip()) > 0 and self.command_line.strip()[0] == '{':
            self.load_args_from_json_string(self.command_line)


class ConfigCommand(CommandBase):
    cmd = "config"
    needs_admin = False
    help_cmd = "config [sleep=<s>] [jitter=<pct>]"
    description = "View or update agent runtime configuration (sleep interval, jitter)"
    version = 1
    author = "@0xbbuddha"
    argument_class = ConfigArguments
    attackmapping = []
    attributes = CommandAttributes(supported_os=[SupportedOS.Linux, SupportedOS.Windows])

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        parts = []
        s = task.args.get_arg("sleep")
        j = task.args.get_arg("jitter")
        if s:
            parts.append("sleep={}s".format(s))
        if j:
            parts.append("jitter={}%".format(j))
        task.display_params = "  ".join(parts) if parts else "(show current)"
        return task

    async def process_response(self, response: AgentResponse):
        pass
