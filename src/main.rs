mod sql;

use crate::sql::*;
use std::env;

use actix_web::*;

#[get("/get-todos")]
async fn get_all() -> impl Responder {
    let rows = get_all_tasks().await.unwrap();
    let serialized = serde_json::to_string(&rows).unwrap();
    HttpResponse::Ok()
        .insert_header(("Access-Control-Allow-Origin", "*"))
        .body(serialized)
}

#[get("/add-todo/{id}/{text}")]
async fn add(path: web::Path<(i32, String)>) -> impl Responder {
    let (id, text) = path.into_inner();
    add_task(id, &text).await;
    let res = format!("Added todo with ID {id} and text {text}");
    HttpResponse::Ok()
        .insert_header(("Access-Control-Allow-Origin", "*"))
        .body(res)
}

#[get("/delete-todo/{id}")]
async fn delete(path: web::Path<i32>) -> impl Responder {
    let id = path.into_inner();
    delete_task(id).await;
    let res = format!("Deleted todo with ID {id}");
    HttpResponse::Ok()
        .insert_header(("Access-Control-Allow-Origin", "*"))
        .body(res)
}

#[get("/get-count")]
async fn get_count_handler() -> impl Responder {
    let count = get_count().await;
    let serialized = serde_json::to_string(&count).unwrap();
    HttpResponse::Ok()
        .insert_header(("Access-Control-Allow-Origin", "*"))
        .body(serialized)
}

#[get("/inc-count")]
async fn inc_count_handler() -> impl Responder {
    inc_count().await;

    HttpResponse::Ok()
        .insert_header(("Access-Control-Allow-Origin", "*"))
        .body("Successfully incremented id!")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .service(get_all)
            .service(delete)
            .service(add)
            .service(get_count_handler)
            .service(inc_count_handler)
    })
    .bind(("0.0.0.0", env::var("BIND_PORT").unwrap().parse().unwrap()))?
    .run()
    .await
}
