/*  Title:      Pure/Tools/build_history.scala
    Author:     Makarius

Build other history versions.
*/

package isabelle


import java.io.{File => JFile}
import java.util.Calendar


object Build_History
{
  /* build_history */

  private val default_rev = "tip"
  private val default_threads = 1
  private val default_heap = 500
  private val default_isabelle_identifier = "build_history"

  def build_history(
    hg: Mercurial.Repository,
    rev: String = default_rev,
    isabelle_identifier: String = default_isabelle_identifier,
    components_base: String = "",
    fresh: Boolean = false,
    nonfree: Boolean = false,
    threads: Int = default_threads,
    arch_64: Boolean = false,
    heap: Int = default_heap,
    more_settings: List[String] = Nil,
    verbose: Boolean = false,
    build_args: List[String] = Nil): Process_Result =
  {
    if (threads < 1) error("Bad threads value < 1: " + threads)
    if (heap < 100) error("Bad heap value < 100: " + heap)

    hg.update(rev = rev, clean = true)
    if (verbose) Output.writeln(hg.log(rev, options = "-l1"))

    def bash(script: String): Process_Result =
      Isabelle_System.bash("env ISABELLE_IDENTIFIER=" + File.bash_string(isabelle_identifier) +
        " " + script, cwd = hg.root.file, env = null)

    def isabelle(cmdline: String): Process_Result = bash("bin/isabelle " + cmdline)
    val isabelle_home_user: Path = Path.explode(isabelle("getenv -b ISABELLE_HOME_USER").check.out)


    /* reset settings */

    val etc_settings: Path = isabelle_home_user + Path.explode("etc/settings")

    if (etc_settings.is_file && !File.read(etc_settings).startsWith("# generated by Isabelle"))
      error("Cannot proceed with existing user settings file: " + etc_settings)

    Isabelle_System.mkdirs(etc_settings.dir)

    File.write(etc_settings,
      "# generated by Isabelle " + Calendar.getInstance.getTime + "\n" +
      "#-*- shell-script -*- :mode=shellscript:\n")


    /* component settings */

    val component_settings =
    {
      val components_base_path =
        if (components_base == "") isabelle_home_user.dir + Path.explode("contrib")
        else Path.explode(components_base).expand

      val catalogs =
        if (nonfree) List("main", "optional", "nonfree") else List("main", "optional")

      catalogs.map(catalog =>
        "init_components " + File.bash_path(components_base_path) +
          " \"$ISABELLE_HOME/Admin/components/" + catalog + "\"")
    }

    File.append(etc_settings, "\n" + Library.terminate_lines(component_settings))


    /* ML settings */

    val ml_settings =
    {
      val windows_32 = "x86-windows"
      val windows_64 = "x86_64-windows"
      val platform_32 = isabelle("getenv -b ISABELLE_PLATFORM32").check.out
      val platform_64 = isabelle("getenv -b ISABELLE_PLATFORM64").check.out
      val platform_family = isabelle("getenv -b ISABELLE_PLATFORM_FAMILY").check.out

      val polyml_home = Path.explode(isabelle("getenv -b ML_HOME").check.out).dir
      def ml_home(platform: String): Path = polyml_home + Path.explode(platform)

      def err(platform: String): Nothing =
        error("Platform " + platform + " unavailable on this machine")

      def check_dir(platform: String): Boolean =
        platform != "" && ml_home(platform).is_dir

      val ml_platform =
        if (Platform.is_windows && arch_64) {
          if (check_dir(windows_64)) windows_64 else err(windows_64)
        }
        else if (Platform.is_windows && !arch_64) {
          if (check_dir(windows_32)) windows_32
          else platform_32  // x86-cygwin
        }
        else {
          val (platform, platform_name) =
            if (arch_64) (platform_64, "x86_64-" + platform_family)
            else (platform_32, "x86-" + platform_family)
          if (check_dir(platform)) platform else err(platform_name)
        }

      val ml_options =
        "-H " + heap + " --gcthreads " + threads +
        (if (ml_platform.endsWith("-windows")) " --codepage utf8" else "")

      List(
        "ML_HOME=" + File.bash_path(ml_home(ml_platform)),
        "ML_PLATFORM=" + quote(ml_platform),
        "ML_OPTIONS=" + quote(ml_options))
    }


    /* thread settings */

    val thread_settings =
      List(
        "ISABELLE_JAVA_SYSTEM_OPTIONS=\"$ISABELLE_JAVA_SYSTEM_OPTIONS -Disabelle.threads=" + threads + "\"",
        "ISABELLE_BUILD_OPTIONS=\"threads=" + threads + "\"")


    /* build */

    File.append(etc_settings, "\n" +
      cat_lines(List(ml_settings, thread_settings).map(Library.terminate_lines(_))))

    if (more_settings.nonEmpty)
      File.append(etc_settings, "\n" + Library.terminate_lines(more_settings))

    isabelle("components -a").check.print_if(verbose)
    isabelle("jedit -b" + (if (fresh) " -f" else "")).check.print_if(verbose)

    isabelle("build " + File.bash_args(build_args))
  }


  /* command line entry point */

  def main(args: Array[String])
  {
    Command_Line.tool0 {
      var allow = false
      var components_base = ""
      var heap: Option[Int] = None
      var threads = default_threads
      var isabelle_identifier = default_isabelle_identifier
      var more_settings: List[String] = Nil
      var fresh = false
      var arch_64 = false
      var nonfree = false
      var rev = default_rev
      var verbose = false

      val getopts = Getopts("""
Usage: isabelle build_history [OPTIONS] REPOSITORY [ARGS ...]

  Options are:
    -A           allow irreversible cleanup of REPOSITORY clone (required)
    -C DIR       base directory for Isabelle components (default: $ISABELLE_HOME_USER/../contrib)
    -H HEAP      minimal ML heap in MB (default: """ + default_heap + """ for x86, """ + default_heap * 2 + """ for x86_64)
    -M THREADS   number of threads for Poly/ML RTS and Isabelle/ML (default: """ + default_threads + """)
    -N NAME      alternative ISABELLE_IDENTIFIER (default: """ + default_isabelle_identifier + """)
    -e TEXT      additional text for generated etc/settings
    -f           fresh build of Isabelle/Scala components (recommended)
    -m ARCH      processor architecture (32=x86, 64=x86_64, default: x86)
    -n           include nonfree components
    -r REV       update to revision (default: """ + default_rev + """)
    -v           verbose

  Build Isabelle sessions from the history of another REPOSITORY clone,
  passing ARGS directly to its isabelle build tool.
""",
        "A" -> (_ => allow = true),
        "C:" -> (arg => components_base = arg),
        "H:" -> (arg => heap = Some(Value.Int.parse(arg))),
        "M:" -> (arg => threads = Value.Int.parse(arg)),
        "N:" -> (arg => isabelle_identifier = arg),
        "e:" -> (arg => more_settings = more_settings ::: List(arg)),
        "f" -> (_ => fresh = true),
        "m:" ->
          {
            case "32" | "x86" => arch_64 = false
            case "64" | "x86_64" => arch_64 = true
            case bad => error("Bad processor architecture: " + quote(bad))
          },
        "n" -> (_ => nonfree = true),
        "r:" -> (arg => rev = arg),
        "v" -> (_ => verbose = true))

      val more_args = getopts(args)
      val (root, build_args) =
        more_args match {
          case root :: build_args => (root, build_args)
          case _ => getopts.usage()
        }

      using(Mercurial.open_repository(Path.explode(root)))(hg =>
        {
          if (!allow)
            error("Repository " + hg + " will be cleaned thoroughly!\n" +
              "Provide option -A to allow this explicitly.")

          val res =
            build_history(hg, rev = rev, isabelle_identifier = isabelle_identifier,
              components_base = components_base, fresh = fresh, nonfree = nonfree,
              threads = threads, arch_64 = arch_64,
              heap = heap.getOrElse(if (arch_64) default_heap * 2 else default_heap),
              more_settings = more_settings, verbose = verbose, build_args = build_args)
          res.print
          if (!res.ok) sys.exit(res.rc)
        })
    }
  }
}
