#!/bin/bash
base_dir=$HOME/dotfiles
backup_dir="$base_dir/.backups.local"
backup_prefix="$backup_dir/$(date '+%Y%m%d%H%M%S')"

mkdir -p "$backup_dir"

link_file() {
    local src=$1 dst=$2
	local backup_dst=false delete_dst=false link_dst=true
    if [[ -e $dst ]]; then
		current_link=$(readlink "$dst")
		if [[ "$current_link" != "$src" ]]; then
			while true; do
				printf "File already exists: %s. What do you want?\n" "$dst"
				printf "[r]eplace; [b]ack up; [s]kip: "
				read -r op
				case $op in
					r )
						delete_dst=true
						link_dst=true
						break;;
					b )
						backup_dst=true
						delete_dst=true
						link_dst=true
						break;;
					s )
						link_dst=false
						break;;
					* )
					   echo "Unrecognized option: $op";;
			   esac
			done
		else
            echo "$dst is already linked to $src"
			link_dst=false
		fi
    fi
	if [[ "$backup_dst" == "true" ]]; then
		local backup_file
        backup_file="$backup_prefix$(basename "$dst")"
		mv "$dst" "$backup_file"
		echo "$dst was backed up to $backup_file"
	fi
	if [[ "$delete_dst" == "true" ]]; then
		rm -rf "$dst"
	fi
	if [[ "$link_dst" == "true" ]]; then
		ln -s "$src" "$dst"
		return 0
	fi
	return 1
}

echo "Setting up git"
link_file "$base_dir/git/gitconfig" ~/.gitconfig

echo "Setting up zsh..."
link_file "$base_dir/zsh/oh-my-zsh" ~/.oh-my-zsh
link_file "$base_dir/zsh/zshrc" ~/.zshrc
link_file "$base_dir/zsh/zsh-custom-themes" ~/.zsh-custom-themes

echo "Setting up vim..."
if link_file "$base_dir/vim/vimrc" ~/.vimrc ; then
	vim +PlugInstall +qall
fi

echo "Setting up tmux..."
link_file "$base_dir/tmux/tmux" ~/.tmux
link_file "$base_dir/tmux/tmux.conf" ~/.tmux.conf

printf "Set up hammerspoons config? [yn]"
read -r op
if [[ "$op" == "y" ]]; then
    link_file "$base_dir/hammerspoon" ~/.hammerspoon
fi

# Set up neovim
mkdir -p ~/.config
ln -s ~/.vim ~/.config/nvim
ln -s ~/.vimrc ~/.config/nvim/init.vim

echo "Done"
