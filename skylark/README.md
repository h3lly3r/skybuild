<h1>SkyBuild</h1>

<h3>What?</h3>
A very lightweight and simple tool for managing small, simple c and c++ projects, and provide ccls the data it wants for proper linting.

<h3>Why?</h3>
It grew endlessly frustrating needing to use cmake to generate a .ccls and command_config.json for my LSP. In IDE's like vscode, this is not an issue, but it is for smaller/simpler text editors like vim. The purpose of skybuild it to make it much easier to set up a project, navigate to it, add a new source file / include a directory, and then generate the files your LSP is looking for.

<h3>Who?</h3>
Who is this for? People who work on small, simple projects in c/c++, but cannot be bothered essentially rewriting a part of a cmake files document and getting that all to every time they create a new project or expand on it. Who am I? You don't know me.

<h3>How?</h3>
its very simple, but does require you to configure your .bashrc and .vimrc just a little. theres included shellscript and vimscript for copy pasting. skybuild.sh originally just did what the things it needed to do in the background without interfacing with your terminal. now, it gathers some of the things it needs to do into steps and formats them to be executed by your terminal or vim. It will independently do things like navigating your directory looking for for files and validating what its about to do, but when its time to actually affect something it will output the instructions as a string to be evaluated by your shell or vim. this is particularly helpful for navigating to a project. when you have a project setup, you can simply write "$ skylark projectname" and it will navigate you to the root folder of your project. this makes debugging easy as if something goes wrong, instead of giving the command to the function youve setup in your bashrc, you can simply write "$ ./skylark/skybuild.sh whatever commands youre debugging" and it will just echo the string to your console. to debug vim, use "$ ./skylark/skybuild.sh \[RUNTIME_VIM\] the commands here" and it will show you how its outputing the instructions to your vimrc. 

<h3>Isn't that a little risky?</h3>
Yes, but i wrote this program for myself, so i know what its doing. If you can write any shellscript or vimscript at all, youre probably much better at it than I am, and with such a small amount of code (713 lines for the skybuild.sh file and under a hundred for the bashrc and vimrc each) it should be very easy to read through and verify what its doing yourself, if you want to use this.


This project technically started a couple of years ago, when I was first learning c/c++ and would write a single-line g++ command in shellscript and run the script whenever i wanted to compile. As i grew tired of rewriting my script between compilations and frustrated with the extra work needed to set up LSP support for c/c++ in vim, i decided to write a tool which has saved my many hours of my life already. I'm sharing this as open source so it might help other people working on small c/c++ projects who cant be bothered with using more cumbersome build tools.

Right now theres a lot that can still be done. for now, it defaults to using the c++ 11 standard on all projects,which as the script is right now will need to be changed manually in the script. its the same with defaulting to linux, all the preprocessor definitions for warning flags, and the default included directorys for standard includes is a bit embarrasing. its a list  i build over a year or so of frustratedly trying to tell vscode/whatever other application where to find my standard library headers, so it probably has a lot of redundency. There are also unimplemented commands, missing functionality in vim,and much else to do, but i spent a couple of days on this and got it to a state where it worked well on my system, so this is the state its in for now.

If you want to make any contributions or requests, feel free to ask - although its worth mentioning im not very active online so i might not see this straight away.