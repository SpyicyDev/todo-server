//use openssl::ssl::SslMethod;
//use postgres_openssl::MakeTlsConnector;
use rustls::Certificate;
use rustls_pemfile::{certs, read_one};
use std::io::BufReader;

use std::env;

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct TodoItem {
    pub todo_id: i32,
    pub todo_text: String,
}

pub async fn get_all_tasks() -> Option<Vec<TodoItem>> {
    let client = prep_sql().await;

    let get = client.prepare("SELECT * FROM todos").await.unwrap();

    let rows = client
        .query(&get, &[])
        .await
        .unwrap()
        .iter()
        .map(|row| TodoItem {
            todo_id: row.get(0),
            todo_text: row.get(1),
        })
        .collect::<Vec<_>>();

    Option::from(rows)
}

pub async fn add_task(id: i32, text: &String) {
    let client = prep_sql().await;

    let post = client
        .prepare("INSERT INTO todos (todo_id, todo_text) VALUES ($1, $2)")
        .await
        .unwrap();

    client
        .execute(&post, &[&id, text])
        .await
        .expect("Unable to POST new data into todos table!");
}

pub async fn delete_task(id: i32) {
    let client = prep_sql().await;

    let delete = client
        .prepare("DELETE FROM todos WHERE todo_id = $1")
        .await
        .unwrap();

    client
        .execute(&delete, &[&id])
        .await
        .expect("Unable to DELETE data from todos table!");
}

pub async fn get_count() -> i32 {
    let client = prep_sql().await;

    let get_id = client.prepare("SELECT * FROM id").await.unwrap();

    let res = client.query_one(&get_id, &[]).await.unwrap();

    res.get(0)
}

pub async fn inc_count() {
    let client = prep_sql().await;

    let inc_id = client
        .prepare("UPDATE id SET id = id + 1 WHERE true")
        .await
        .unwrap();

    client
        .execute(&inc_id, &[])
        .await
        .expect("Unable to increment ID!");
}

async fn prep_sql() -> tokio_postgres::Client {
    let mut root_store = rustls::RootCertStore::empty();
    let f = env::var("CA_CERT").unwrap();
    println!("{:?}", f);
    let f = f.as_str();
    println!("{:?}", f);
    let f = f.as_bytes();
    println!("{:?}", f);
    let mut f = BufReader::new(f);
    let thing: rustls_pemfile::Item = read_one(&mut f).unwrap().unwrap();
    let _ = root_store.add(&Certificate(
        if let rustls_pemfile::Item::X509Certificate(c) = thing {
            c
        } else {
            vec![]
        },
    ));
    /*
                   certs(&mut f)
        .unwrap()
        .iter()
        .for_each(|cert| root_store.add(&Certificate(cert.clone())).unwrap());
    */
    let config = rustls::ClientConfig::builder()
        .with_safe_defaults()
        .with_root_certificates(root_store)
        .with_no_client_auth();
    let tls = tokio_postgres_rustls::MakeRustlsConnect::new(config);
    /*
    let mut builder = openssl::ssl::SslConnector::builder(SslMethod::tls()).unwrap();
    builder.set_ca_file("/tmp/ca-certificate.crt").unwrap();
    let connector = MakeTlsConnector::new(builder.build());
    */
    let (client, connection) =
        tokio_postgres::connect(env::var("DB_ADDRESS").unwrap().as_str(), tls)
            .await
            .unwrap();

    // The connection object performs the actual communication with the database,
    // so spawn it off to run on its own.
    tokio::spawn(async move {
        if let Err(e) = connection.await {
            eprintln!("connection error: {}", e);
        }
    });

    client
}
