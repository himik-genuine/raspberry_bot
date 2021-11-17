### raspberry_bot

Simple Telegram bot for monitoring and control linux on Raspberry Pi boards. Requires [Ruby](https://www.ruby-lang.org) to run.

Allows you to monitor CPU temperature and RAM usage. Allows to execute shell commands, both by calling the command directly through the "/shell" bot command, and through aliases previously written to the user_commands.cfg file.

### bot.cfg options explanation:
- token - Place your bot token obtained from @BotFather here. You can read more about tokens here - https://core.telegram.org/bots#6-botfather This option required to start the bot.
- users - Place your telegram id(or comma-separeted list of id's) here. If you don't know it for now, you can just leave this field blank, and recieve id from bot itself in reply to your first message.
- api_url - URL to telegram bot API. Just leave it as it is.
- api_timeout - Timeout for bot long polling requests. Usually does not require changes.
- monitoring - Activates monitoring module if set to true. This option can be changed via bot, but in case if you need disable monitoring via cfg-file for some reason, remove this line from it.
- monitor_update - Time in seconds after which monitoring checks the value of the metrics.
- cpu_temperature - CPU themperature threshold in °C. Remove this line to disable CPU themperature monitoring.
- used_memory - Used RAM threshold in %. Remove this line to disable RAM usage monitoring.
- commands_timeout - Timeot in seconds for any command started via bot /shell. In case something was started that will never finish. Ping without option -с, for example.
- messages_limit - Maximum number of messages that contain the shell-command output.
- download_directory - Directory where the bot saves the files downloaded via telegram.

### user_commands.cfg format:

/bot_command#any_shell_command, parameters and pipelines are valid.

For the option command you need to install some extra packages just remove form user_commands.cfg
sudo apt-get install nmap 
sudo apt-get install speedtest-cli


