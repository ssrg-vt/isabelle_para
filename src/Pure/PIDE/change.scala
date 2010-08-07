/*  Title:      Pure/PIDE/change.scala
    Author:     Fabian Immler, TU Munich
    Author:     Makarius

Changes of plain text, resulting in document edits.
*/

package isabelle


object Change
{
  val init = new Change(Document.NO_ID, None, Nil, Future.value(Nil, Document.init))

  abstract class Snapshot
  {
    val document: Document
    val node: Document.Node
    val is_outdated: Boolean
    def convert(offset: Int): Int
    def revert(offset: Int): Int
  }
}

class Change(
  val id: Document.Version_ID,
  val parent: Option[Change],
  val edits: List[Document.Node_Text_Edit],
  val result: Future[(List[Document.Edit[Command]], Document)])
{
  /* ancestor versions */

  def ancestors: Iterator[Change] = new Iterator[Change]
  {
    private var state: Option[Change] = Some(Change.this)
    def hasNext = state.isDefined
    def next =
      state match {
        case Some(change) => state = change.parent; change
        case None => throw new NoSuchElementException("next on empty iterator")
      }
  }


  /* editing and state assignment */

  def join_document: Document = result.join._2
  def is_assigned: Boolean = result.is_finished && join_document.assignment.is_finished


  /* snapshot */

  def snapshot(name: String, pending_edits: List[Text_Edit]): Change.Snapshot =
  {
    val latest = this
    val stable = latest.ancestors.find(_.is_assigned)
    require(stable.isDefined)

    val edits =
      (pending_edits /: latest.ancestors.takeWhile(_ != stable.get))((edits, change) =>
          (for ((a, eds) <- change.edits if a == name) yield eds).flatten ::: edits)
    lazy val reverse_edits = edits.reverse

    new Change.Snapshot {
      val document = stable.get.join_document
      val node = document.nodes(name)
      val is_outdated = !(pending_edits.isEmpty && latest == stable.get)
      def convert(offset: Int): Int = (offset /: edits)((i, edit) => edit.convert(i))
      def revert(offset: Int): Int = (offset /: reverse_edits)((i, edit) => edit.revert(i))
    }
  }
}