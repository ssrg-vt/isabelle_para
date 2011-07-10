/*  Title:      Tools/jEdit/src/protocol_dockable.scala
    Author:     Makarius

Dockable window for protocol messages.
*/

package isabelle.jedit


import isabelle._

import java.lang.System

import scala.actors.Actor._
import scala.swing.{TextArea, ScrollPane}

import org.gjt.sp.jedit.View


class Protocol_Dockable(view: View, position: String) extends Dockable(view, position)
{
  private val text_area = new TextArea
  set_content(new ScrollPane(text_area))


  /* main actor */

  private val main_actor = actor {
    loop {
      react {
        case input: Isabelle_Process.Input =>
          Swing_Thread.now { text_area.append(input.toString + "\n") }

        case result: Isabelle_Process.Result =>
          Swing_Thread.now { text_area.append(result.message.toString + "\n") }

        case bad => System.err.println("Protocol_Dockable: ignoring bad message " + bad)
      }
    }
  }

  override def init() { Isabelle.session.raw_messages += main_actor }
  override def exit() { Isabelle.session.raw_messages -= main_actor }
}
