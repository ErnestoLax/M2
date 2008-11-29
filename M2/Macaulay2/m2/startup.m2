-- startup.m2

-- this file gets incorporated into the executable file bin/M2 as the string 'startupString2'

--		Copyright 1993-2003 by Daniel R. Grayson

errorDepth = 0						    -- without this, we may see no error messages the second time through
debuggingMode = true
stopIfError = false
gotarg := arg -> any(commandLine, s -> s == arg)
if gotarg "--stop" then stopIfError = true

firstTime := class PackageDictionary === Symbol

-- here we put local variables that might be used by the global definitions below
match := X -> null =!= regex X

if regex(".*/","/aa/bb") =!= {(0, 4)}
or regex(".*/","aabb") =!= null
then error "regex regular expression library not working"

-- we do this bit *before* "debug Core", so that Core (the symbol, not the package), which may not be there yet, ends up in the right dictionary
if firstTime then (
     assert = x -> (
	  if class x =!= Boolean then error "'assert' expected true or false";
	  if not x then error "assertion failed");
     PackageDictionary = new Dictionary;
     dictionaryPath = append(dictionaryPath,PackageDictionary);
     assert( not isGlobalSymbol "Core" );
     PackageDictionary#("Package$Core") = getGlobalSymbol(PackageDictionary,"Core");
     )

-- we need access to the private symbols -- (we remove the Core private dictionary later.)
if not firstTime then debug Core

toString := value getGlobalSymbol if firstTime then "simpleToString" else "toString"

-- this next bit has to be *parsed* after the "debug" above, to prevent the symbols from being added to the User dictionary
if firstTime then (
     -- all global definitions go here, because after loaddata is run, we'll come through here again
     -- with all these already done and global variables set to read-only

     filesLoaded = new MutableHashTable;
     loadedFiles = new MutableHashTable;
     notify = false;
     nobanner = false;
     texmacsmode = false;
     restarting = false;
     restarted = false;
     srcdirs = {};

     markLoaded = (fullfilename,origfilename,notify) -> ( 
	  fullfilename = minimizeFilename fullfilename;
	  filesLoaded#origfilename = fullfilename; 
	  loadedFiles##loadedFiles = toAbsolutePath fullfilename; 
	  if notify then stderr << "--loaded " << fullfilename << endl;
	  );
     normalPrompts = () -> (
	  lastprompt := "";
	  ZZ#{Standard,InputPrompt} = lineno -> concatenate(newline, lastprompt = concatenate(interpreterDepth:"i", toString lineno, " : "));
	  ZZ#{Standard,InputContinuationPrompt} = lineno -> #lastprompt; -- will print that many blanks, see interp.d
	  symbol currentPrompts <- normalPrompts;	    -- this avoids the warning about redefining a function
	  );
     normalPrompts();
     noPrompts = () -> (
	  ZZ#{Standard,InputPrompt} = lineno -> "";
	  ZZ#{Standard,InputContinuationPrompt} = lineno -> "";
	  symbol currentPrompts <- noPrompts;
	  );

     startFunctions := {};
     addStartFunction = f -> ( startFunctions = append(startFunctions,f); f);
     runStartFunctions = () -> scan(startFunctions, f -> f());

     endFunctions := {};
     addEndFunction = f -> ( endFunctions = append(endFunctions,f); f);
     runEndFunctions = () -> (
	  save := endFunctions;
	  endFunctions = {};
	  scan(save, f -> f());
	  endFunctions = save;
	  );

     simpleExit := exit;
     exit = ret -> ( runEndFunctions(); simpleExit ret );

     File << Thing  := File => (x,y) -> printString(x,toString y);
     File << Net := File << Symbol := File << String := printString;
     << Thing := x -> stdio << x;
     String | String := String => concatenate;
     Function _ Thing := Function => (f,x) -> y -> f splice (x,y);
     String | ZZ := String => (s,i) -> concatenate(s,toString i);
     ZZ | String := String => (i,s) -> concatenate(toString i,s);

     new HashTable from List := HashTable => (O,v) -> hashTable v;

     Manipulator = new Type of BasicList;
     Manipulator.synonym = "manipulator";
     new Manipulator from Function := Manipulator => (Manipulator,f) -> new Manipulator from {f};
     Manipulator Database := Manipulator File := Manipulator NetFile := (m,o) -> m#0 o;

     Manipulator Nothing := (m,null) -> null;
     File << Manipulator := File => (o,m) -> m#0 o;
     NetFile << Manipulator := File => (o,m) -> m#0 o;
     Nothing << Manipulator := (null,m) -> null;

     TeXmacsBegin = ascii 2;
     TeXmacsEnd   = ascii 5;

     close = new Manipulator from close;
     closeIn = new Manipulator from closeIn;
     closeOut = new Manipulator from closeOut;
     flush = new Manipulator from flush;
     endl = new Manipulator from endl;

     Thing#{Standard,Print} = x ->  (
	  << newline << concatenate(interpreterDepth:"o") << lineNumber << " = ";
	  try << x;
	  << newline << flush;
	  );

     first = x -> x#0;
     last = x -> x#-1;
     lines = x -> (
	  l := separate x;
	  if l#-1 === "" then drop(l,-1) else l);

     isFixedExecPath = filename -> (
	  -- this is the way execvp(3) decides whether to search the path for an executable
	  match("/", filename)
	  );
     re := "/";						    -- /foo/bar
     if version#"operating system" === "MicrosoftWindows" 
     then re = re | "|.:/";				    -- "C:/FOO/BAR"
     re = re | "|\\$";					    -- $www.uiuc.edu:80
     re = re | "|!";					    -- !date
     isAbsolutePathRegexp := "^(" | re | ")";		    -- whether the path will work from any directory and get to the same file
     re = re | "|\\./";					    -- ./foo/bar
     re = re | "|\\.\\./";				    -- ../foo/bar
     isStablePathRegexp   := "^(" | re | ")";               -- whether we should search only in the current directory (or current file directory)
     isAbsolutePath = filename -> match(isAbsolutePathRegexp, filename);
     isStablePath = filename -> match(isStablePathRegexp, filename);
     concatPath = (a,b) -> if isAbsolutePath b then b else a|b;

     toAbsolutePath = pth -> if pth =!= "stdio" and not isAbsolutePath pth then "/" | relativizeFilename("/", pth) else pth;

     copyright = (
	  "Macaulay 2, version " | version#"VERSION" | newline
	  | "--Copyright 1993-2008, D. R. Grayson and M. E. Stillman" | newline
	  | "--GC " | version#"gc version" | ", by H. Boehm and Alan J. Demers" | newline
	  | "--Singular-Factory " | version#"factory version" | ", by G.-M. Greuel et al." | newline
	  | "--Singular-Libfac " | version#"libfac version" | ", by M. Messollen" | newline
	  | "--NTL " | version#"ntl version" | ", by V. Shoup" | newline
     	  | "--GNU MP " | version#"gmp version" | ", by T. Granlund et al." | newline
     	  | "--MPFR " | version#"mpfr version" | ", by Free Software Foundation" | newline
	  | "--BLAS and LAPACK 3.0" | ", by J. Dongarra et al."
	  );

     scan(
	  { ("factory version", "3.0.2"), ("libfac version", "3.0.1") },
	  (k,v) -> if version#k < v then stderr << "--warning: old " << k << " " << version#k << " < " << v << endl);

     use = identity;				  -- temporary, until methods.m2

     Attributes = new MutableHashTable;
     -- values are hash tables with keys Symbol, String, Net (as symbols); replaces ReverseDictionary and PrintNames
     setAttribute = (val,attr,x) -> (
	  if Attributes#?val then Attributes#val else Attributes#val = new MutableHashTable
	  )#attr = x;
     hasAnAttribute = (val) -> Attributes#?val;
     hasAttribute = (val,attr) -> Attributes#?val and Attributes#val#?attr;
     getAttribute = (val,attr) -> Attributes#val#attr;
     getAttributes = (attr0) -> (
	  r := new MutableHashTable;
	  scan(values Attributes, tab -> scan(pairs tab, (attr,x) -> if attr === attr0 then r#x = true));
	  keys r);
     removeAttribute = (val,attr) -> remove(Attributes#val,attr);
     protect PrintNet;
     protect PrintNames;
     protect ReverseDictionary;

     globalAssign = (s,v) -> if v =!= value s then (
	  X := class value s;
	  m := lookup(GlobalReleaseHook,X);
	  if m =!= null then m(s,value s);
	  Y := class v;
	  n := lookup(GlobalAssignHook,Y);
	  if n =!= null then n(s,v);
	  s <- v);
     globalAssignFunction = (X,x) -> (
	  if not hasAttribute(x,ReverseDictionary) then setAttribute(x,ReverseDictionary,X);
	  use x;
	  );
     globalReleaseFunction = (X,x) -> (
	  if hasAttribute(x,ReverseDictionary)
	  and getAttribute(x,ReverseDictionary) === X
	  then removeAttribute(x,ReverseDictionary)
	  );
     globalAssignment = X -> (
	  if instance(X, VisibleList) then apply(X,globalAssignment)
	  else if instance(X,Type) then (
	       X.GlobalAssignHook = globalAssignFunction; 
	       X.GlobalReleaseHook = globalReleaseFunction;
	       )
	  else error "expected a type";
	  );
     globalAssignment {Type,Function};
     scan(dictionaryPath, dict -> (
	       scan(pairs dict, (nm,sym) -> (
			 x := value sym;
			 if instance(x, Function) or instance(x, Type) then setAttribute(x,ReverseDictionary,sym)))));

     applicationDirectorySuffix = () -> (
	  if version#"operating system" === "MacOS" then "Library/Application Support/Macaulay2/" else ".Macaulay2/"
	  );
     applicationDirectory = () -> (
	  if instance(applicationDirectorySuffix, Function)
	  then homeDirectory | applicationDirectorySuffix()
	  else homeDirectory | applicationDirectorySuffix
	  );

     dumpdataFile = null;
     )

prefixDirectory = null					    -- prefix directory, after installation, e.g., "/usr/local/"
encapDirectory = null	   -- encap directory, after installation, if present, e.g., "/usr/local/encap/Macaulay2-0.9.5/"

fullCopyright := false
matchpart := (pat,i,s) -> substring_((regex(pat, s))#i) s
notdir := s -> matchpart("[^/]*$",0,s)
noloaddata := false
nosetup := false
noinitfile = false
interpreter := commandInterpreter

{*
getRealPath := fn -> (					    -- use this later if realpath doesn't work
     local s;
     while ( s = readlink fn; s =!= null ) do fn = if isAbsolutePath s then s else minimizeFilename(fn|"/../"|s);
     fn)
*}

pathsearch := e -> (
     if not isFixedExecPath e then (
	  -- we search the path, but we don't do it the same way execvp does, too bad.
	  PATH := separate(":",if "" =!= getenv "PATH" then getenv "PATH" else ".:/bin:/usr/bin");
	  PATH = apply(PATH, x -> if x === "" then "." else x);
	  scan(PATH, p -> if fileExists (p|"/"|e) then (e = p|"/"|e; break));
	  );
     e)

phase := 1

silence := arg -> null
notyeterr := arg -> error("command line option ", arg, " not re-implemented yet")
notyet := arg -> if phase == 1 then (
     << "warning: command line option " << arg << " not re-implemented yet" << newline << flush;
     )
obsolete := arg -> error ("warning: command line option ", arg, " is obsolete")
progname := notdir commandLine#0

local dump
usage := arg -> (
     << "usage:"             << newline
     << "    " << progname << " [option ...] [file ...]" << newline
     << "options:"  << newline
     << "    --help             print this brief help message and exit" << newline
     << "    --no-backtrace     print no backtrace after error" << newline
     << "    --copyright        display full copyright messasge" << newline
     << "    --no-debug         do not enter debugger upon error" << newline
     << "    --dumpdata         read source code, dump data if so configured, exit (no init.m2)" << newline
     << "    --fullbacktrace    print full backtrace after error" << newline
     << "    --no-loaddata      don't try to load the dumpdata file" << newline
     << "    --int              don't handle interrupts" << newline -- handled by M2lib.c
     << "    --notify           notify when loading files during initialization" << newline
     << "                       and when evaluating command line arguments" << newline
     << "    --no-prompts       print no input prompts" << newline;
     << "    --no-readline      don't use readline" << newline;
     << "    --no-setup         don't try to load setup.m2 or to loaddata" << newline
     << "    --no-personality   don't set the personality and re-exec M2 (linux only)" << newline
     << "    --prefix DIR       set prefixDirectory" << newline
     << "    --print-width n    set printWidth=n (the default is the window width)" << newline
     << "    --restarted        used internally to indicate this is a restart" << newline
     << "    --script           as first argument, interpret second argument as name of a script" << newline
     << "                       implies --stop, --no-debug, --silent and -q" << newline
     << "                       see scriptCommandLine" << newline
     << "    --silent           no startup banner" << newline
     << "    --stop             exit on error" << newline
     << "    --texmacs          TeXmacs session mode" << newline
     << "    --version          print version number and exit" << newline
     << "    -q                 don't load user's init.m2 file or use packages in home directory" << newline
     << "    -E '...'           evaluate expression '...' before initialization" << newline
     << "    -e '...'           evaluate expression '...' after initialization" << newline
     << "    --top-srcdir '...' add top source or build tree '...' to initial path" << newline
     << "environment:"       << newline
     << "    M2ARCH             a hint to find the dumpdata file as" << newline
     << "                       bin/../cache/Macaulay2-$M2ARCH-data, where bin is the" << newline
     << "                       directory containing the Macaulay2 executable" << newline
     << "    EDITOR             default text editor" << newline
     << "    LOADDATA_IGNORE_CHECKSUMS (loaddata: disable verification of memory map checksums)" << newline
     << "    COMPAREVDSO               (loaddata: enable verification for the vdso segment)" << newline
     << "    LOADDATA_DEBUG            (loaddata: verbose debugging messages)" << newline
     ;)

tryLoad := (ofn,fn) -> if fileExists fn then (
     r := simpleLoad fn;
     markLoaded(fn,ofn,notify);
     true) else false

showMaps := () -> (
     if version#"operating system" === "SunOS" then (
	  stack lines get ("!/usr/bin/pmap "|processID())
	  )
     else if version#"operating system" === "Linux" and fileExists("/proc/"|toString processID()|"/maps") then (
	  stack lines get("/proc/"|toString processID()|"/maps")
	  )
     else "memory maps not available"
     )


argno := 1

action := hashTable {
     "-h" => arg -> (usage(); exit 0),
     "-mpwprompt" => notyeterr,
     "-n" => obsolete,
     "-q" => arg -> noinitfile = true,
     "-s" => obsolete,
     "-silent" => obsolete,
     "-tty" => notyet,
     "--copyright" => arg -> if phase == 1 then fullCopyright = true,
     "--dumpdata" => arg -> (noinitfile = noloaddata = true; if phase == 4 then dump()),
     "--help" => arg -> (usage(); exit 0),
     "--int" => arg -> arg,
     "--no-backtrace" => arg -> if phase == 1 then backtrace = false,
     "--no-debug" => arg -> debuggingMode = false,
     "--no-loaddata" => arg -> if phase == 1 then noloaddata = true,
     "--no-personality" => arg -> arg,
     "--no-prompts" => arg -> if phase == 3 then noPrompts(),
     "--no-readline" => arg -> arg,			    -- handled in d/stdio.d
     "--no-setup" => arg -> if phase == 1 then noloaddata = nosetup = true,
     "--notify" => arg -> if phase <= 2 then notify = true,
     "--no-tty" => arg -> arg,			    -- handled in d/stdio.d
     "--script" => arg -> error "--script option should be first argument, of two",
     "--silent" => arg -> nobanner = true,
     "--stop" => arg -> (if phase == 1 then stopIfError = true; debuggingMode = false;), -- see also M2lib.c and tokens.d
     "--restarted" => arg -> restarted = true,
     "--texmacs" => arg -> (
	  if phase == 1 then (
	       topLevelMode = TeXmacs;
	       printWidth = 80;
	       )
	  else if phase == 3 then (
	       topLevelMode = TeXmacs;
	       printWidth = 80;
	       )
	  else if phase == 4 then (
	       texmacsmode = true;
	       topLevelMode = TeXmacs;
	       addEndFunction(() -> if texmacsmode then (
			 if restarting 
			 then stderr << "Macaulay 2 restarting..." << endl << endl << flush
			 else (
			      stderr << "Macaulay 2 exiting" << flush;
			      << TeXmacsEnd << endl << flush)));
	       )
	  ),
     "--version" => arg -> ( << version#"VERSION" << newline; exit 0; )
     };

valueNotify := arg -> (
     if notify then stderr << "--evaluating command line argument " << argno << ": " << format arg << endl;
     value arg)

initialPath := {}

action2 := hashTable {
     "--srcdir" => arg -> if phase == 2 then (
	  if not match("/$",arg) then arg = arg|"/";
	  srcdirs = append(srcdirs,arg);
	  initialPath = join(initialPath,select({arg|"Macaulay2/m2/",arg|"Macaulay2/packages/"},isDirectory));
	  ),
     "-E" => arg -> if phase == 3 then valueNotify arg,
     "-e" => arg -> if phase == 4 then valueNotify arg,
     "--print-width" => arg -> if phase == 3 then printWidth = value arg,
     "--prefix" => arg -> if phase == 1 or phase == 3 then (
	  if not match("/$",arg) then arg = arg | "/";
	  prefixDirectory = arg;
	  )
     }

scriptCommandLine = {}

processCommandLineOptions := phase0 -> (			    -- 3 passes
     ld := loadDepth;
     loadDepth = loadDepth + 1;
     phase = phase0;
     argno = 1;
     if commandLine#?1 and commandLine#1 == "--script" then (
	  if phase <= 2 then (
	       clearEcho stdio;
	       debuggingMode = false;
	       stopIfError = noinitfile = nobanner = true;
	       )
	  else if phase == 4 then (
	       if not commandLine#?2 then error "script file name missing";
	       arg := commandLine#2;
	       scriptCommandLine = drop(commandLine,2);
	       if instance(load, Function) then load arg else simpleLoad arg;
	       exit 0))
     else (
	  if notify then stderr << "--phase " << phase << endl;
	  while argno < #commandLine do (
	       arg = commandLine#argno;
	       if action#?arg then action#arg arg
	       else if action2#?arg then (
		    if argno < #commandLine + 1
		    then action2#arg commandLine#(argno = argno + 1)
		    else error("command line option ", arg, " missing argument")
		    )
	       else if arg#0 == "-" then (
		    stderr << "error: unrecognized command line option: " << arg << endl;
		    usage();
		    exit 1;
		    )
	       else if phase == 4 then if instance(load, Function) then load arg else simpleLoad arg;
	       argno = argno+1;
	       );
	  loadDepth = ld;
	  ))

if firstTime then processCommandLineOptions 1

exe := minimizeFilename (
     {*
     -- this can be a reliable way to get the executable in linux
     -- but we don't want to use it because we don't want to chase symbolic links and it does that for us
     processExe := "/proc/self/exe";
     if fileExists processExe and readlink processExe =!= null then readlink processExe
     else 
     *}
     if isAbsolutePath commandLine#0 then commandLine#0 else
     if isStablePath commandLine#0 then concatenate(currentDirectory|commandLine#0)
     else pathsearch commandLine#0)
if not isAbsolutePath exe then exe = currentDirectory | exe ;
dir  := s -> ( m := regex(".*/",s); if m === null or 0 === #m then "./" else substring(m#0#0,m#0#1-1,s))
base := s -> ( m := regex(".*/",s); if m === null or 0 === #m then s    else substring(m#0#1,      s))
exe = concatenate(realpath dir exe, "/", base exe)
issuffix := (s,t) -> t =!= null and s === substring(t,-#s)
bindir := dir exe | "/";
currentLayout = (
     if issuffix(Layout#2#"bin",bindir) then Layout#2 else
     if issuffix(Layout#1#"bin",bindir) then Layout#1
     )
prefixDirectory = if currentLayout =!= null then substring(bindir,0,#bindir-#currentLayout#"bin")
if readlink exe =!= null then (
     exe2 := (
	  if isAbsolutePath readlink exe
     	  then readlink exe
     	  else realpath dir exe | "/" | readlink exe);
     bindir2 := dir exe2 | "/";
     currentLayout2 := (
	  if issuffix(Layout#2#"bin",bindir2) then Layout#2 else
	  if issuffix(Layout#1#"bin",bindir2) then Layout#1
	  );
     )
prefixDirectory2 := if currentLayout2 =!= null then substring(bindir2,0,#bindir2-#currentLayout2#"bin")
if prefixDirectory2 =!= null
   and isDirectory(prefixDirectory2|currentLayout2#"packages")
   and not isDirectory(prefixDirectory|currentLayout#"packages")
then (
     prefixDirectory = prefixDirectory2;
     currentLayout = currentLayout2;
     )
stA := "StagingArea/"
topBuilddir := (
     if issuffix(stA,prefixDirectory) then substring(prefixDirectory,0,#prefixDirectory-#stA)
     else
     if issuffix(stA,prefixDirectory2) then substring(prefixDirectory2,0,#prefixDirectory2-#stA))
topSrcdir := if topBuilddir =!= null and fileExists(topBuilddir|"srcdir") then minimizeFilename(topBuilddir|first lines get(topBuilddir|"srcdir"));

describePath := () -> (
     stderr << "--file search starts here:" << endl;
     for d in path do (
     	  stderr << "--    " << d << endl;
	  ))

loadSetup := () -> (
     if notify then describePath();
     for d in path do (
	  fn := minimizeFilename(d|"setup.m2");
	  if tryLoad("setup.m2", fn) then return;
	  );
     error "can't load setup.m2; run with --notify option to see the path used for searching"
     )

dump = () -> (
     if not version#"dumpdata" then (
	  error "not configured for dumping data with this version of Macaulay 2";
	  );
     arch := if getenv "M2ARCH" =!= "" then getenv "M2ARCH" else version#"architecture";
     fn := (
	  if prefixDirectory =!= null then concatenate(prefixDirectory, replace("PKG","Core",currentLayout#"packagecache"), "Macaulay2-", arch, "-data")	  
	  );
     if fn === null then error "can't find cache directory for dumpdata file";
     fntmp := fn | ".tmp";
     fnmaps := fn | ".maps";
     fnmaps << showMaps() << endl << close;
     runEndFunctions();
     dumpdataFile = toAbsolutePath fn;					    -- so we know after "loaddata" where we put the file
     collectGarbage();
     interpreterDepth = 0;
     stderr << "--dumping to " << fntmp << endl;
     dumpdata fntmp;
     stderr << "--success" << endl;
     moveFile(fntmp,fn,Verbose=>true);
     exit 0;
     )

if firstTime and not nobanner then (
     if topLevelMode === TeXmacs then stderr << TeXmacsBegin << "verbatim:";
     stderr << (if fullCopyright then copyright else first separate copyright) << newline << flush;
     if topLevelMode === TeXmacs then stderr << TeXmacsEnd << flush)
if firstTime and not noloaddata and version#"dumpdata" then (
     -- try to load dumped data
     arch := if getenv "M2ARCH" =!= "" then getenv "M2ARCH" else version#"architecture";
     datafile := minimizeFilename (
	  if prefixDirectory =!= null then concatenate(prefixDirectory, replace("PKG","Core",currentLayout#"packagecache"), "Macaulay2-", arch, "-data")
	  else concatenate("Macaulay2-", arch, "-data")
	  );
     if fileExists datafile then (
	  if notify then stderr << "--loading cached memory data from " << datafile << newline << flush;
     	  try loaddata(notify,datafile);
	  if notify then stderr << "--warning: unable to load data from " << datafile << newline << flush))

scan(commandLine, arg -> if arg === "-q" or arg === "--dumpdata" then noinitfile = true)
homeDirectory = getenv "HOME" | "/"

path = (x -> select(x, i -> i =!= null)) deepSplice {
	  if not noinitfile then (
	       applicationDirectory() | "local/" | Layout#1#"packages", 
	       applicationDirectory() | "code/"
	       ),
	  if prefixDirectory =!= null then (
	       if topBuilddir =!= null then (
		    if topSrcdir =!= null then (
		    	 topSrcdir|"Macaulay2/m2/",
		    	 topSrcdir|"Macaulay2/packages/"
			 ),
		    topBuilddir|"Macaulay2/m2/",
		    topBuilddir|"Macaulay2/packages/"
		    ),
	       prefixDirectory | replace("PKG","Core",currentLayout#"package"),
	       prefixDirectory | currentLayout#"packages"
	       )
	  }

if firstTime then normalPrompts()

printWidth = fileWidth stdio

processCommandLineOptions 2				    -- just for path to core files and packages

path = join(initialPath, path)

if firstTime and not nosetup then loadSetup()

-- remove the Core private dictionary -- it was added by "debug" above
-- and install a local way to use private global symbols
local core
if not nosetup then (
     dictionaryPath = select(dictionaryPath, d -> d =!= Core#"private dictionary");
     core = nm -> value Core#"private dictionary"#nm;
     ) else (
     core = nm -> value getGlobalSymbol nm
     )

processCommandLineOptions 3
(core "runStartFunctions")()

errorDepth = loadDepth
if class Core =!= Symbol and not core "noinitfile" then (
     -- the location of init.m2 is documented in the node "initialization file"
     tryLoad ("init.m2", applicationDirectory() | "init.m2");
     tryLoad ("init.m2", "init.m2");
     );

processCommandLineOptions 4
interpreterDepth = 0
errorDepth = loadDepth+1      -- anticipate loadDepth being incremented
n := interpreter()	      -- loadDepth is incremented by commandInterpreter
if class n === ZZ and 0 <= n and n < 128 then exit n
if n === null then exit 0
debuggingMode = false
stopIfError = true
stderr << "error: can't interpret return value as an exit code" << endl
exit 1

-- Local Variables:
-- compile-command: "make -C $M2BUILDDIR/Macaulay2/d && make -C $M2BUILDDIR/Macaulay2/m2 "
-- End:
