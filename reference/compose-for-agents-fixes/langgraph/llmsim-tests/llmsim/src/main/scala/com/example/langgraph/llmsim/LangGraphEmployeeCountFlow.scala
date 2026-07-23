package com.example.langgraph.llmsim

import com.alai.llmsim.{Script, ScriptSource}
import com.alai.llmsim.Script.*

object LangGraphEmployeeCountFlow extends ScriptSource {

  private val EmployeeCount =
    """(?is)employee_count\s*\n-+\s*\n(\d+)\b""".r

  val script: Script = Script.exactly(
    toolCall(
      id = "tables-1",
      name = "list_tables",
      arguments = "{}"
    ),

    toolCall(
      id = "employee-schema-1",
      name = "describe_table",
      arguments = """{"table_name":"employee"}"""
    ),

    toolCall(
      id = "employee-count-1",
      name = "execute_sql",
      arguments =
        """{"sql_query":"SELECT COUNT(*) AS employee_count FROM employee"}"""
    ),

    replyFromToolResult("employee-count-1") { result =>
      EmployeeCount.findFirstMatchIn(result) match {
        case Some(count) =>
          s"There are ${count.group(1)} employees in the system."

        case None =>
          s"Unable to determine the employee count from the database result: $result"
      }
    }
  )
}
