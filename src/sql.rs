use openssl::ssl::{SslConnector, SslMethod};
use postgres_openssl::MakeTlsConnector;

use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
pub struct TodoItem {
    pub todo_id: i32,
    pub todo_text: String
}

pub async fn SqlQuery(id: i32, text: String, operation: i32) -> Option<Vec<TodoItem>> {
    let mut builder = SslConnector::builder(SslMethod::tls()).unwrap();
    builder.set_ca_file("ca-certificate.crt").unwrap();
    let connector = MakeTlsConnector::new(builder.build());

    let (client, connection) =
        tokio_postgres::connect("postgresql://doadmin:AVNS_AphIofhrOO6vcAN8gCP@db-postgresql-nyc1-78249-do-user-7865624-0.b.db.ondigitalocean.com:25060/defaultdb?sslmode=require", connector).await.unwrap();

    // The connection object performs the actual communication with the database,
    // so spawn it off to run on its own.
    tokio::spawn(async move {
        if let Err(e) = connection.await {
            eprintln!("connection error: {}", e);
        }
    });

    let get = client.prepare("SELECT * FROM todos").await.unwrap();
    let delete = client.prepare("DELETE FROM todos WHERE todo_id = $1").await.unwrap();
    let post = client.prepare("INSERT INTO todos (todo_id, todo_text) VALUES ($1, $2)").await.unwrap();

    if operation == 0 {
        let rows = client
            .query(&get, &[])
            .await.unwrap()
            .iter().map(|row| {
            TodoItem {
                todo_id: row.get(0),
                todo_text: row.get(1),
            }
        }).collect::<Vec<_>>();

        Option::from(rows)
    } else {
        None
    }

}