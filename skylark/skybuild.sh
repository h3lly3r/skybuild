SCRIPT_PATH=$(dirname "$(realpath "$0")")
ABSOLUTE_PATH="$(pwd)/"
FALSE="FALSE"
TRUE="TRUE"
ERROR="__ERROR__"
SHDEBUG="$TRUE"
TRACE="$TRUE"
TRACE_FILE="$ABSOLUTE_PATH/.skytrace"

BASH_RUNTIME_IDENTIFIER="[RUNTIME_BASH]"
VIM_RUNTIME_IDENTIFIER="[RUNTIME_VIM]"

RUNTIME="$BASH_RUNTIME_IDENTIFIER"
TRACED_CODE=""
HISTORY=""

FIRST_SHELL_COMMAND="$TRUE"
shellout=""
trace()
{
  if [[ "$TRACE" == "$TRUE" ]]; then
    TRACED_CODE="$TRACED_CODE\\n-->$1"
  fi
}
shell()
{
  if [ -n "$1" ]; then
    trace "[SHELL]-->CMD"
    if [[ "$FIRST_SHELL_COMMAND" == "$FALSE" ]]; then
      shellout="$shellout;$1"
    else
      shellout="$1"
      FIRST_SHELL_COMMAND="$FALSE"
    fi
  fi
}
shellcd()
{
  trace "[SHELL_CD]-->$1"
  if [[ "$RUNTIME" == "$VIM_RUNTIME_IDENTIFIER" ]]; then
    shell "[CHANGE_DIR]-->$1"
  else
    shell "cd $1"
  fi
}
rewrite()
{
  trace "[REWRITE]-->DATA>>$2"
  if [[ ! -n "$1" || ! -n "$2" ]] ; then
    error "invalid args for rewrite, dest: $2 data: $1"
  fi
  if [[ "$RUNTIME" == "$VIM_RUNTIME_IDENTIFIER" ]]; then
    shell "[REWRITE]-->$1>>$2"
  else
    shell "echo -e \"$1\" >> $2"
  fi
}
execute()
{
  trace "[EXECUTE]-->$1"
  if [[ "$RUNTIME" == "$VIM_RUNTIME_IDENTIFIER" ]]; then
    shell "[EXECUTE]-->$1"
  else
    shell "$1"
  fi
}
error()
{
  trace "[ERROR]-->$1" 
  text_cache="$HISTORY"
  cache_line ""
  cache_line "ERROR_CALL"
  printline "'[ERROR] - $1 (in ${FUNCNAME[1]} at line ${BASH_LINENO[0]}) $SCRIPT_PATH'"
  echo "$shellout"
  > "$TRACE_FILE"
  printf "$text_cache${shellout//;/$'\n'}\n\n" >> "$SKY_COMMAND_HISTORY"
  if [[ "$TRACE" == "$TRUE" ]]; then  
    printf "${TRACED_CODE//%/%%}" >> "$TRACE_FILE"
  fi
  exit 0
}
debug()
{
  trace "[DEBUG]-->$1"
  if [[ "$SHDEBUG" == "$TRUE" ]]; then 
      printline "'[DEBUG] - $1 (in ${FUNCNAME[1]} at line ${BASH_LINENO[0]}) $SCRIPT_PATH'" 
  fi
}
printline()
{
  trace "[PRINTLINE]-->$1"
  if [[ "$RUNTIME" == "$VIM_RUNTIME_IDENTIFIER" ]]; then
    shell "[PRINTLINE]--$1"
  else
    shell "echo \"$1\""
  fi
}
end()
{
  trace "[END]" 
  text_cache="$HISTORY"
  cache_line ""
  cache_line "EXIT_CALL"
  #echo  "$text_cache${shellout//;/$'\n'}\n\n" 
  echo "$shellout"
  end_history="$text_cache${shellout//;/$'\n'}\n\n"
  end_history="${end_history//%/%%}"
  printf "$end_history" >> "$SKY_COMMAND_HISTORY"
  > "$TRACE_FILE"
  if [[ "$TRACE" == "$TRUE" ]]; then  
    printf "${TRACED_CODE//%/%%}" >> "$TRACE_FILE"
  fi
  exit 0
}

SKY_DIRECTORY="$HOME/.skylark"
SKY_CACHE="$SKY_DIRECTORY/cache"
SKY_COMMAND_HISTORY="$SKY_DIRECTORY/history"
PROJECT_CACHE=".skyproject"

project_name=$ERROR

project_dir="$(pwd)/"

STD_CPP_17="-std=c++17"
STD_CPP_11="-std=c++11"
cpp_standard=$STD_CPP_11
CLANG="/usr/bin/clang"
CLANG_PP="/usr/bin/clang++"
compilerpath="$CLANG"


source_files=()
include_dirs=()

DEFAULT_SOURCE="main.cpp"
DEBUG_FLAG="-g"
warning_flags="-pedantic -Wshadow -Wextra -Wall -Wno-error=unused-function -Wno-error=unused-variable"

default_includes=(
  "/usr/include/c++/11"
	"/usr/include/x86_64-linux-gnu/c++/11"
	"/usr/include/c++/11/backward"
	"/usr/lib/gcc/x86_64-linux-gnu/11/include"
	"/usr/local/include"
	"/usr/include/x86_64-linux-gnu"
	"/usr/include"
)

project_cache_lines=()

PROJECT_NAME_IDENTIFIER="[PROJECT_NAME]"
PROJECT_INCLUDES_IDENTIFIER="[PROJECT_INCLUDES]"
PROJECT_SOURCES_IDENTIFIER="[PROJECT_SOURCES]"
PROJECT_STANDARD_IDENTIFIER="[PROJECT_STANDARD]"

READ_STATE="READ_STATE_UNINI"

win32="_WIN32"
win64="_WIN64"
linux="__linux__"
platform=$linux

x86_64="__x86_64__"
i386="__i386__"
ARM="__arm__"

TAC="--"
DEBUG="--debug"
PERF="--performance"
OPTIM="--optimized"
STATIC="--static"
NOWARN="--nowarnings"

declare -A script_flags

compile_args[COMPILE_DEBUG]="$FALSE"
compile_args[COMPILE_PERF]="$FALSE"
compile_args[COMPILE_OPTIM]="$FALSE"
compile_args[COMPILE_STATIC]="$FALSE"
compile_args[COMPILE_NOWARN]="$FALSE"

text_cache=""
cache_line() 
{
  text_cache="$text_cache$1\\n"
}

skylark_cache_lines=()
read_skylark_cache()
{
  debug " accessing skylark global cache: $SKY_CACHE"
  if [ ! -f "$SKY_CACHE" ]; then sherror "invalid skylark cache, has skylark been installed?."; fi
  while IFS= read -r line; do
    skylark_cache_lines+=("$line")
  done < "$SKY_CACHE"
}

command_extension=""
cache_command() 
{
  if [ ! -z "$command_extension" ]; then
    command_extension="$command_extension "
  fi
  command_extension="$command_extension$1"
}


affirm_cache()
{
  if [ ! -f "$(pwd)/$PROJECT_CACHE" ]; then
    find_ancestor_project
    if [ ! -f "$(pwd)/$PROJECT_CACHE" ]; then
      error "could not find project cache"
    fi
  fi
}


ancestor_project_dir="$ERROR"
find_ancestor_project()
{
  old_dir=$(pwd)
  current_dir=$(pwd)
  while [ "$current_dir" != "/" ]; do
    debug "checking $current_dir"
    if [ -f "$current_dir/$PROJECT_CACHE" ]; then 
      ancestor_project_dir="$current_dir"; 
      debug "found"
      break
    fi
    current_dir=$(dirname "$current_dir")
    cd "$current_dir"
  done
  if [ ! -f "$current_dir/$PROJECT_CACHE" ]; then
    cd "$old_dir"
  fi
  debug "$ancestor_project_dir"
}

match_state()
{
  if [[ "$1" == "" ]]; then
    continue
  elif [[ "$1" == "$PROJECT_NAME_IDENTIFIER" \
     || "$1" == "$PROJECT_INCLUDES_IDENTIFIER"\
     || "$1" == "$PROJECT_SOURCES_IDENTIFIER"\
     || "$1" == "$PROJECT_STANDARD_IDENTIFIER" ]]; then
    READ_STATE="$1"
  else
    case "$READ_STATE" in
      "$PROJECT_NAME_IDENTIFIER")
        project_name="$1"
        ;;
      "$PROJECT_INCLUDES_IDENTIFIER")
        include_dirs+=("$1")
        ;;
      "$PROJECT_SOURCES_IDENTIFIER")
        source_files+=("$1")
        ;;
      #"$PROJECT_STANDARD_IDENTIFIER")
        #cpp_standard="$1"
        #;;
      *)
        #
        ;;
    esac
  fi
}


read_cache()
{
  trace "[READ_CACHE]--|"
  if [ ! -f "$PROJECT_CACHE" ]; then sherror "invalid project directory."; fi
  while IFS= read -r line; do
    project_cache_lines+=("$line")
  done < "$PROJECT_CACHE"
  for LINE in "${project_cache_lines[@]}"; do
    if [[ "$LINE" == "" ]]; then
      continue
    else
      match_state $LINE
    fi
  done
}


write_cache()
{
  > $PROJECT_CACHE
  text_cache=""
  cache_line "$PROJECT_NAME_IDENTIFIER"
  cache_line "$project_name"
  cache_line ""
  cache_line "$PROJECT_STANDARD_IDENTIFIER"
  cache_line "$cpp_standard"
  cache_line ""
  cache_line "$PROJECT_INCLUDES_IDENTIFIER"
  for INCLUDE in "${include_dirs[@]}"; do
    debug "caching include $INCLUDE"
    if [[ "$INCLUDE" == "" ]]; then
      continue
    fi
    cache_line "$INCLUDE"
  done
  cache_line ""
  cache_line "$PROJECT_SOURCES_IDENTIFIER"
  for SOURCE in "${source_files[@]}"; do
    if [[ "$SOURCE" == "" ]]; then
      continue
    fi
    cache_line "$SOURCE"
  done
  cache_line ""
  rewrite "$text_cache" "$PROJECT_CACHE"
}

write_skylark_cache()
{
  > $SKY_CACHE
  debug "updating skylark projects cache"
  text_cache=""
  for LINE in "${skylark_cache_lines[@]}"; do
    cache_line "$LINE"
    debug "added $LINE"
  done
  rewrite "$text_cache" "$SKY_CACHE"
}



build_command_extension()
{
  command_extension=""
  #cache_command "$cpp_standard"
  #cache_command "$warning_flags"
  cache_command "$compiler"
  for include in "${default_includes[@]}"; do
    cache_command "-I$include"
  done
  cache_command "-I$project_dir"
  for include in "${include_dirs[@]}"; do
    cache_command "-I$include"
  done
  cache_command "$definitions"
}

SOURCE_PATH_PLACEHOLDER="<<SOURCE_PATH_PLACEHOLDER>>"
build_command_ccjson_extenstion()
{
  command_extension=""
  cache_command "$compilerpath"
  cache_command "-o"
  cache_command "$SOURCE_PATH_PLACEHOLDER.0"
  cache_command "-c"
  cache_command "$cpp_standard"
  cache_command "$warning_flags"
  cache_command "-D$platform"
  for DIR in "${include_dirs[@]}"; do
    cache_command "-I$DIR"
  done
  for DDIR in "${default_includes[@]}"; do
    cache_command "-I$DDIR"
  done
  cache_command "$SOURCE_PATH_PLACEHOLDER"
}

build_lsp_data() 
{
  trace "[BUILD_LSP_DATA]--|"
  ccls_cache=".ccls"
  > $ccls_cache
  compile_command_json="compile_commands.json"
  > $compile_command_json
  text_cache=""
  cache_line "clang"
  cache_line "%c %cpp $cpp_standard"
  cache_line "%h %hpp --include=Global.h"
  for DIR in "${include_dirs[@]}"; do
    cache_line "-I$DIR"
  done
  for DDIR in "${default_includes[@]}"; do
    cache_line "-I$DDIR"
  done
  rewrite "$text_cache" "$ccls_cache"
  build_command_ccjson_extenstion
  text_cache=""
  cache_line "["
  FIRST_SOURCE_FILE="$TRUE"
  for FILE in "${source_files[@]}"; do
    trace "[BUILD_LSP_DATA]-->ADDING_SOURCE-->$FILE"
    if [[ "$FILE" == "" ]]; then
      continue
    fi
    if [[ "$FIRST_SOURCE_FILE" == "$FALSE" ]]; then
      cache_line ","
    fi
    first_substitution="${command_extension/$SOURCE_PATH_PLACEHOLDER/$FILE}"
    substituted="${first_substitution/$SOURCE_PATH_PLACEHOLDER/$FILE}"
    cache_line "    {"
    cache_line "        \\\"command\\\": \\\"$substituted\\\","
    cache_line "        \\\"directory\\\": \\\"$(pwd)\\\","
    cache_line "        \\\"file\\\": \\\"$FILE\\\""
    text_cache="$text_cache    }"
    FIRST_SOURCE_FILE="$FALSE"
  done
  text_cache="$text_cache\\n]"
  rewrite "$text_cache" "$compile_command_json"
}

new_project()
{
  debug "creating new project $1"
  if [ ! -d "$SKY_DIRECTORY" ]; then
    error "skylark build manager not installed"
  fi
  if [ ! -f "$SKY_CACHE" ]; then
    error "skylark build manager not installed"
  fi
  if [ ! -n "$1" ]; then sherror "cannot create unnamed project."; fi
  target_dir="$(pwd)"
  find_ancestor_project
  if [ -f "$(pwd)/$PROJECT_CACHE" ]; then 
    read_cache
    cd "$target_dir"
    error "cannot create project in subdirectory of project $project_name." 
  fi
  cd "$target_dir"
  if find . -type f -name "$PROJECT_CACHE" -print -quit | grep -q .; then
    sherror "cannot create project in ancestral directory of another project"
  fi
  project_name="$1"
  if [ -f "$PROJECT_CACHE" ]; then
    read_cache
    error "project $project_name already exists in this directory."; 
  fi
  write_cache
  build_lsp_data
  read_skylark_cache
  skylark_cache_lines+=("$1")
  skylark_cache_lines+=("$(pwd)")
  write_skylark_cache
  printline "project $project_name ceated successfully in $project_dir"
  end 
}

add_source()
{
  trace "[ADD_SOURCE]-->$@"
  affirm_cache
  read_cache
  new_sources=("$@")
  for ((i=0; i < ${#new_sources[@]}; i++)); do
    trace "[ADD_SOURCE]-TESTING-->$(pwd)/${new_sources[i]}"
    this_source="$(pwd)/${new_sources[i]}"
    if [ -f "${new_sources[i]}" ]; then
      trace "[ADD_SOURCE]-TESTED_AS-->IS_FILE"
      printline "adding source file $this_source to project."
      source_files+=("$this_source")
    else
      trace "[ADD_SOURCE]-TESTED_AS-->NOT_FILE"
      printline "failed to find source file $this_source."
    fi
  done
  write_cache
  build_lsp_data
  end
}

add_include()
{
  affirm_cache
  read_cache
  new_includes=("$@")
  for ((i=0; i < ${#new_includes[@]}; i++)); do
    if [ -d "${new_includes[i]}" ]; then 
      this_include="$(pwd)/${new_includes[i]}"
      printline "adding included directory $this_include to project."
      include_dirs+=("$this_include")
    else 
      printline "failed to find directory ${new_includes[i]}."
    fi
  done
  debug "Printing include_dirs list"
  for DIR in "${include_dirs[@]}"; do
    debug $DIR
  done
  write_cache
  build_lsp_data
  end
}

recache()
{
  affirm_cache
  read_cache
  build_lsp_data
  end 
}

set_flag() 
{
  case "$1" in
  "$DEBUG")
    compile_args[COMPILE_DEBUG]="$TRUE"
    ;;
  "$PERF")
    compile_args[COMPILE_PERF]="$TRUE"
    ;;
  "$OPTIM")
    compile_args[COMPILE_OPTIM]="$TRUE"
    ;;
  "$STATIC")
    compile_args[COMPILE_STATIC]="$TRUE"
    ;;
  "$NOWARN")
    compile_args[COMPILE_NOWARN]="$TRUE"
    ;;
  *)
    find_project
    ;;
esac

  local setting=$1
  compile_args[$setting]=$TRUE
}

build()
{
  affirm_cache
  for arg in "$@"; do
    if [[ ${script_flags[$arg]} ]]; then set_flag $arg; fi
  done
  source_file="src/${source_files[0]}.cpp"
  output_file="build/${source_files[0]}"
  warning_flags=""
  if [ "${compile_args[COMPILE_NOWARN]}" == "$TRUE" ]; then
    warning_flags="-pedantic -Wshadow -Wextra -Wall -g "
  fi
  includes="-I. -Iinclude -Icommon "
  optimization=""
  if [ "${compile_args[COMPILE_OPTIM]}" == "$TRUE" ]; then
    optimized="-O2 "
  fi
  definitions="-D$platform -DNAME_STRING="\"$name\"" "
  if [ "${compile_args[COMPILE_DEBUG]}" == "$TRUE" ]; then
    definitions="$definitions-DSESSION_DEBUG "
  fi  
  if [ "${compile_args[COMPILE_PERF]}" == "$TRUE" ]; then
    definitions="$definitions-DPERFORMANCE "
  fi
  static=""
  if [ "${compile_args[COMPILE_STATIC]}" == "$TRUE" ]; then
    static="-static "
  fi
  libraries=""
  build_command_extension
  compile_output=$(g++ $command_extension -o $output_file $source_file $static $libraries 2>&1)
  printline "$compile_output"
  if [ ! -f "/$output_file" ]; then
    printline "compiled successfully."
    execute "$(pwd)/$output_file"
  else
    printline "compilation failed."
  fi
  end
}

find_project()
{
  debug "searching for project $1"
  if [ -n "$1" ]; then
    read_skylark_cache
    for ((i=0; i < ${#skylark_cache_lines[@]}; i++)); do
      if [[ "${skylark_cache_lines[i]}" == "$1" ]]; then
        shellcd "${skylark_cache_lines[i + 1]}"
        end
      fi
    done
    error "unable to find project $1"
  fi
  find_ancestor_project
  if [[ "$ancestor_project_dir" == "$ERROR" ]]; then 
    ancestor_project_dir=$(find . -type f -name "$PROJECT_CACHE" -print -quit) ; 
  fi
  if [ -f "$(pwd)/$PROJECT_CACHE" ]; then
    shellcd "$ancestor_project_dir"
    read_cache
    printline "located root directory for $project_name"
    end
  fi
  error "could not locate lineal project directory"
}


install_sky()
{
  if [ ! -d "$SKY_DIRECTORY" ]; then
    printline "creating sky directory $SKY_DIRECTORY"
    mkdir "$SKY_DIRECTORY"
  fi
  if [ ! -f "$SKY_CACHE" ]; then
    printline "creating sky cache $SKY_CACHE"
    > $SKY_CACHE
  fi
  printline "sky installed successfully"
  end
}


print_cached()
{
  read_cache
  for DIR in "${include_dirs[@]}"; do
    printline "$DIR"
  done
  for SRC in "${source_files[@]}"; do
    printline "$SRC"
  done
  end
}

match_command()
{
  debug "match_command() given $@"
  local given="$1"
  shift
  local shifted=("$@")
  case $given in
    "--printcached")
      print_cached
      ;;
    "--ping")
      echo "pong"
      exit 0
      ;;
    "--install")
      install_sky
      ;;
    "--new")
      new_project "${shifted[0]}"
      ;;
    "--source")
      add_source ${shifted[@]}
      ;;
    "--include")
      add_include ${shifted[@]}
      ;;
    "--recache")
      recache
      ;;
    "--build")
      build ${shifted[@]}
      ;;
    "--list")
      # list all cached projects in /.sky/cached_projects
      sherror "list unimplemented"
      ;;
    "--order-sources")
      # list the order of source files as they appear in $PROJECT_CACHE
      sherror "order-sources unimplemented"
      ;;
    "--reorder-sources")
      # takes a sequence of source files as they would appear in $PROJECT_CACHE, but rearranges their actual sequence in the cache (if they are found)
      # this is to make sure the sources are in the correct order when the compile command is given
      sherror "reorder-sources unimplemented"
      ;;
    "$VIM_RUNTIME_IDENTIFIER")
      RUNTIME="$VIM_RUNTIME_IDENTIFIER"    
      match_command ${shifted[@]}
      ;;
    "$BASH_RUNTIME_IDENTIFIER")
      RUNTIME="$BASH_RUNTIME_IDENTIFIER"
      match_command ${shifted[@]}
      ;;
    *)
      find_project $given
      ;;
  esac
}

cmd_args=($@)
cache_line "$SCRIPT_PATH called: $(date)"
text_cache="$text_cache~$"
for CMD_ARG in "${cmd_args[@]}"; do 
  text_cache="$text_cache--$CMD_ARG"
done
HISTORY="$text_cache"
match_command $@
end






















