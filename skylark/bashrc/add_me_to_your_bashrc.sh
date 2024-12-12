# runs and evaluates the script, giving it any arguments
skylark()
{
  eval "$(bash ~/.skylark/skybuild.sh $@)"
}

# prints out the data associated with the project file, as well as the names and location of other projects that have been set up
skyprint()
{
  cat ".skyproject"
  cat ".ccls"
  cat "compile_commands.json"
  cat "$HOME/.skylark/cache"
}
