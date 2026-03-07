from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class JobkillArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="task_id",
                type=ParameterType.String,
                description="Task ID of the job to kill",
                parameter_group_info=[ParameterGroupInfo(group_name="Default", ui_position=0, required=True)],
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line) == 0:
            raise ValueError("task_id required")
        if self.command_line.strip()[0] == '{':
            self.load_args_from_json_string(self.command_line)
        else:
            self.add_arg("task_id", self.command_line.strip())


class JobkillCommand(CommandBase):
    cmd = "jobkill"
    needs_admin = False
    help_cmd = "jobkill <task_id>"
    description = "Kill an active background/interactive job by task ID"
    version = 1
    author = "@0xbbuddha"
    argument_class = JobkillArguments
    attackmapping = []
    attributes = CommandAttributes(supported_os=[SupportedOS.Linux, SupportedOS.Windows])

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = task.args.get_arg("task_id")
        return task

    async def process_response(self, response: AgentResponse):
        pass
