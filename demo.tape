Output assets/demo.gif
Set Shell zsh
Set FontSize 16
Set Width 1000
Set Height 500
Set Padding 15
Set Theme "Catppuccin Mocha"
Set TypingSpeed 120ms

# Setup
Hide
Type `export _claude_launch_dir="/Users/avihaymok/Desktop/Avihay/claude-launch"`
Enter
Type `unsetopt PROMPT_CR`
Enter
Type `source "$_claude_launch_dir/integrations/claude-launch.zsh"`
Enter
Type "clear"
Enter
Sleep 500ms
Show

# Demo 1: Just open and pick one item
Type "cc"
Enter
Sleep 5s
Down
Sleep 1s
Down
Sleep 2.5s
Enter
Sleep 3s

# Clear
Ctrl+C
Sleep 500ms
Type "clear"
Enter
Sleep 1.5s

# Demo 2: Search by typing
Type "cc"
Enter
Sleep 5s
Type "resume"
Sleep 2.5s
Enter
Sleep 3s

# Clear
Ctrl+C
Sleep 500ms
Type "clear"
Enter
Sleep 1.5s

# Demo 3: Multi-select to compose
Type "cc"
Enter
Sleep 5s
Down
Tab
Sleep 1.5s
Down
Down
Down
Tab
Sleep 1.5s
Down
Tab
Sleep 1.5s
Enter
Sleep 5s
