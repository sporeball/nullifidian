# nullifidian
# sporeball's fish theme,
# forked from agnoster's theme - https://gist.github.com/3712874
# ---

# options
# you can set these in your config.fish if you want
# ---

# set -g theme_display_user yes
# set -g theme_hide_hostname yes
# set -g theme_hide_hostname no
# set -g default_user your_normal_user

set -g current_bg NONE
set segment_separator \uE0B0

# color settings
# ---

set -g color_user_bg black
set -g color_user_str yellow
set -g color_dir_bg blue
set -g color_dir_str black
set -g color_git_dirty_bg yellow
set -g color_git_dirty_str black
set -g color_git_bg green
set -g color_git_str black
set -g color_status_nonzero_bg red
set -g color_status_nonzero_str black
set -g color_status_superuser_bg black
set -g color_status_superuser_str yellow
set -g color_status_private_bg purple
set -g color_status_private_str black

# Git settings
# ---

set -q fish_git_prompt_untracked_files; or set fish_git_prompt_untracked_files normal

# helper methods
# ---

set -g __fish_git_prompt_showdirtystate 'yes'
set -g __fish_git_prompt_char_dirtystate '*'

function parse_git_dirty
  if [ $__fish_git_prompt_showdirtystate = "yes" ]
    set -l submodule_syntax
    set submodule_syntax "--ignore-submodules=dirty"
    set untracked_syntax "--untracked-files=$fish_git_prompt_untracked_files"
    set git_dirty (command git status --porcelain $submodule_syntax $untracked_syntax 2> /dev/null)
    if [ -n "$git_dirty" ]
        echo -n "$__fish_git_prompt_char_dirtystate"
    end
  end
end

# segment functions
# ---

function prompt_segment -d "draw a segment"
  set -l bg
  set -l fg
  if [ -n "$argv[1]" ]
    set bg $argv[1]
  else
    set bg normal
  end
  if [ -n "$argv[2]" ]
    set fg $argv[2]
  else
    set fg normal
  end
  if [ "$current_bg" != 'NONE' -a "$argv[1]" != "$current_bg" ]
    set_color -b $bg
    set_color $current_bg
    echo -n "$segment_separator "
    set_color -b $bg
    set_color $fg
  else
    set_color -b $bg
    set_color $fg
    echo -n " "
  end
  set current_bg $argv[1]
  if [ -n "$argv[3]" ]
    echo -n -s $argv[3] " "
  end
end

function prompt_finish -d "close open segments"
  if [ -n $current_bg ]
    set_color normal
    set_color $current_bg
    echo -n "$segment_separator "
    set_color normal
  end
  set -g current_bg NONE
end


# theme components
# ---

function prompt_user -d "display current user if different from $default_user"
  if [ "$theme_display_user" = "yes" ]
    if [ "$USER" != "$default_user" -o -n "$SSH_CLIENT" ]
      set USER (whoami)
      get_hostname
      if [ $HOSTNAME_PROMPT ]
        set USER_PROMPT $USER@$HOSTNAME_PROMPT
      else
        set USER_PROMPT $USER
      end
      prompt_segment $color_user_bg $color_user_str $USER_PROMPT
    end
  else
    get_hostname
    if [ $HOSTNAME_PROMPT ]
      prompt_segment $color_user_bg $color_user_str $HOSTNAME_PROMPT
    end
  end
end

function get_hostname -d "set current hostname to prompt variable $HOSTNAME_PROMPT if connected via SSH"
  set -g HOSTNAME_PROMPT ""
  if [ "$theme_hide_hostname" = "no" -o \( "$theme_hide_hostname" != "yes" -a -n "$SSH_CLIENT" \) ]
    set -g HOSTNAME_PROMPT (uname -n)
  end
end

function prompt_dir -d "display the current directory"
  prompt_segment $color_dir_bg $color_dir_str (prompt_pwd)
end

function prompt_git -d "display the current git state"
  set -l ref
  set -l dirty
  if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
    set dirty (parse_git_dirty)
    set ref (command git symbolic-ref HEAD 2> /dev/null)
    if [ $status -gt 0 ]
      set -l branch (command git show-ref --head -s --abbrev |head -n1 2> /dev/null)
      set ref "> $branch "
    end
    set -l branch (echo $ref | sed  "s-refs/heads/--")
    if [ "$dirty" != "" ]
      prompt_segment $color_git_dirty_bg $color_git_dirty_str "$branch $dirty"
    else
      prompt_segment $color_git_bg $color_git_str "$branch"
    end
  end
end

function prompt_status -d "symbols for nonzero exit code, root and background jobs"
  if [ $RETVAL -ne 0 ]
    prompt_segment $color_status_nonzero_bg $color_status_nonzero_str "X"
  end

  if [ "$fish_private_mode" ]
    prompt_segment $color_status_private_bg $color_status_private_str "#"
  end

  # if superuser (uid == 0)
  set -l uid (id -u $USER)
  if [ $uid -eq 0 ]
    prompt_segment $color_status_superuser_bg $color_status_superuser_str "!"
  end
end

# apply theme
# ---

function fish_prompt
  set -g RETVAL $status
  prompt_status
  prompt_user
  prompt_dir
  type -q git; and prompt_git
  prompt_finish
end
