use mysql::*;
use mysql::prelude::*;

use std::result::Result;

pub struct Todo {
    pub todo_id: i32,
    pub todo: String,
}

pub fn sql(item_id: i32, item_text: &str, op: i32) -> Result<Option<Vec<Todo>>, Box<dyn std::error::Error>> {
    let url = "mysql://root:cheese4932@localhost:3306/todo_list";
    let pool = Pool::new(url)?;
    let mut conn = pool.get_conn()?;

    let mut results: Vec<Todo> = vec![];

    if op == 0 { // add
        conn.exec_drop(
            "INSERT INTO todos (todo_id, todo) values (:todo_id, :todo)",
            params! {
                "todo_id" => item_id,
                "todo" => item_text,
            },
        )?;
    } else if op == 1 { // remove
        conn.exec_drop(
            "DELETE FROM todos WHERE todo_id=:todo_id",
            params! {
                "todo_id" => item_id,
            },
        )?;
    } else if op == 2 { // get all
        conn.query_iter("SELECT todo_id, todo FROM todos")
            .unwrap()
            .for_each(|row| {
                let r:(i32, String) = from_row(row.unwrap());
                results.push(Todo { todo_id: r.0, todo: r.1 })
            });
    }

    // returns nothing, the resultant todos, or an error
    Ok(Option::from(results))
}

fn main() {
    let res = sql(0, "", 2).unwrap().unwrap();
    res.iter().for_each(
        |todo| println!("id: {}, task: {}", todo.todo_id, todo.todo)
    );
}