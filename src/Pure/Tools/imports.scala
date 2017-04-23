/*  Title:      Pure/Tools/imports.scala
    Author:     Makarius

Maintain theory imports wrt. session structure.
*/

package isabelle


import java.io.{File => JFile}


object Imports
{
  /* update imports */

  sealed case class Update(range: Text.Range, old_text: String, new_text: String)
  {
    def edits: List[Text.Edit] =
      Text.Edit.replace(range.start, old_text, new_text)

    override def toString: String =
      range.toString + ": " + old_text + " -> " + new_text
  }

  def update_name(keywords: Keyword.Keywords, pos: Position.T, update: String => String)
    : Option[(JFile, Update)] =
  {
    val file =
      pos match {
        case Position.File(file) => Path.explode(file).file.getCanonicalFile
        case _ => error("Missing file in position" + Position.here(pos))
      }

    val text = File.read(file)

    val range =
      pos match {
        case Position.Range(symbol_range) => Symbol.Text_Chunk(text).decode(symbol_range)
        case _ => error("Missing range in position" + Position.here(pos))
      }

    Token.read_name(keywords, range.substring(text)) match {
      case Some(tok) =>
        val s1 = tok.source
        val s2 = Token.quote_name(keywords, update(tok.content))
        if (s1 == s2) None else Some((file, Update(range, s1, s2)))
      case None => error("Name token expected" + Position.here(pos))
    }
  }

  def apply_updates(updates: List[(JFile, Update)])
  {
    val file_updates = (Multi_Map.empty[JFile, Update] /: updates)(_ + _)
    val conflicts =
      file_updates.iterator_list.flatMap({ case (file, upds) =>
        Library.duplicates(upds.sortBy(_.range.start),
          (x: Update, y: Update) => x.range overlaps y.range) match
        {
          case Nil => None
          case bad => Some((file, bad))
        }
      })
    if (conflicts.nonEmpty)
      error(cat_lines(
        conflicts.map({ case (file, bad) =>
          "Conflicting updates for file " + file + bad.mkString("\n  ", "\n  ", "") })))

    for ((file, upds) <- file_updates.iterator_list) {
      val edits =
        upds.sortBy(upd => - upd.range.start).flatMap(upd =>
          Text.Edit.replace(upd.range.start, upd.old_text, upd.new_text))
      val new_text =
        (File.read(file) /: edits)({ case (text, edit) =>
          edit.edit(text, 0) match {
            case (None, text1) => text1
            case (Some(_), _) => error("Failed to apply edit " + edit + " to file " + file)
          }
        })
      File.write_backup2(Path.explode(File.standard_path(file)), new_text)
    }
  }

  def imports(
    options: Options,
    operation_update: Boolean = false,
    progress: Progress = No_Progress,
    selection: Sessions.Selection = Sessions.Selection.empty,
    dirs: List[Path] = Nil,
    select_dirs: List[Path] = Nil,
    verbose: Boolean = false) =
  {
    val full_sessions = Sessions.load(options, dirs, select_dirs)
    val (selected, selected_sessions) = full_sessions.selection(selection)

    val deps =
      Sessions.deps(selected_sessions, progress = progress, verbose = verbose,
        global_theories = full_sessions.global_theories)

    if (operation_update) {
      val updates =
        selected.flatMap(session_name =>
        {
          val info = full_sessions(session_name)
          val session_base = deps(session_name)
          val session_resources = new Resources(session_base)
          val imports_resources = new Resources(session_base.get_imports)

          val local_theories =
            (for {
              (_, name) <- session_base.known.theories_local.iterator
              if session_resources.theory_qualifier(name) == info.theory_qualifier
            } yield name).toSet

          def standard_import(qualifier: String, dir: String, s: String): String =
          {
            val name = imports_resources.import_name(qualifier, dir, s)
            val file = Path.explode(name.node).file
            val s1 =
              imports_resources.session_base.known.get_file(file) match {
                case Some(name1) if session_resources.theory_qualifier(name1) != qualifier =>
                  name1.theory
                case Some(name1) if Thy_Header.is_base_name(s) =>
                  name1.theory_base_name
                case _ => s
              }
            val name2 = imports_resources.import_name(qualifier, dir, s1)
            if (name.node == name2.node) s1 else s
          }

          val updates_root =
            for {
              (_, pos) <- info.theories.flatMap(_._2)
              upd <- update_name(Sessions.root_syntax.keywords, pos,
                standard_import(info.theory_qualifier, info.dir.implode, _))
            } yield upd

          val updates_theories =
            for {
              (_, name) <- session_base.known.theories_local.toList
              (_, pos) <- session_resources.check_thy(name, Token.Pos.file(name.node)).imports
              upd <- update_name(session_base.syntax.keywords, pos,
                standard_import(session_resources.theory_qualifier(name), name.master_dir, _))
            } yield upd

          updates_root ::: updates_theories
        })
      apply_updates(updates)
    }
  }


  /* Isabelle tool wrapper */

  val isabelle_tool =
    Isabelle_Tool("imports", "maintain theory imports wrt. session structure", args =>
    {
      var select_dirs: List[Path] = Nil
      var requirements = false
      var operation_update = false
      var exclude_session_groups: List[String] = Nil
      var all_sessions = false
      var dirs: List[Path] = Nil
      var session_groups: List[String] = Nil
      var options = Options.init()
      var verbose = false
      var exclude_sessions: List[String] = Nil

      val getopts = Getopts("""
Usage: isabelle imports [OPTIONS] [SESSIONS ...]

  Options are:
    -D DIR       include session directory and select its sessions
    -R           operate on requirements of selected sessions
    -U           operation: update theory imports to use session qualifiers
    -X NAME      exclude sessions from group NAME and all descendants
    -a           select all sessions
    -d DIR       include session directory
    -g NAME      select session group NAME
    -o OPTION    override Isabelle system OPTION (via NAME=VAL or NAME)
    -v           verbose
    -x NAME      exclude session NAME and all descendants

  Maintain theory imports wrt. session structure. At least one operation
  needs to be specified (see option -U).
""",
      "D:" -> (arg => select_dirs = select_dirs ::: List(Path.explode(arg))),
      "R" -> (_ => requirements = true),
      "U" -> (_ => operation_update = true),
      "X:" -> (arg => exclude_session_groups = exclude_session_groups ::: List(arg)),
      "a" -> (_ => all_sessions = true),
      "d:" -> (arg => dirs = dirs ::: List(Path.explode(arg))),
      "g:" -> (arg => session_groups = session_groups ::: List(arg)),
      "o:" -> (arg => options = options + arg),
      "v" -> (_ => verbose = true),
      "x:" -> (arg => exclude_sessions = exclude_sessions ::: List(arg)))

      val sessions = getopts(args)
      if (args.isEmpty || !operation_update) getopts.usage()

      val selection =
        Sessions.Selection(requirements, all_sessions, exclude_session_groups,
          exclude_sessions, session_groups, sessions)

      val progress = new Console_Progress(verbose = verbose)

      imports(options, operation_update = operation_update, progress = progress,
        selection = selection, dirs = dirs, select_dirs = select_dirs, verbose = verbose)
    })
}
