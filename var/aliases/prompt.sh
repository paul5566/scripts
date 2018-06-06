
if [[ "$SHELL" == *"bash" ]]
then
	# simple shell prompt
	export PS1="\n\e[32m\u\e[0m@\e[34m\h\e[0m:\e[31m\w\e[0m -- \#:\j \n\e[37;1m>>>\e[0m "	
	# \e[<num>m     ASCI escape ANSI code
	# \u            user name
	# \h            hostname
	# \#            current command number
	# \j            background jobs
fi


if [[ "$SHELL" == *"zsh" ]]
then
	# Switch the ZSH right prompt off
	zsh-norprompt() { export RPROMPT='' ; }
fi
