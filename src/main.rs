mod sql;

use crate::sql::*;

use actix_web::*;


#[get("/")]
async fn GetAll() -> impl Responder {
    let rows = SqlQuery(0, "".to_string(), 0).await.unwrap();

    let serialized = serde_json::to_string(&rows).unwrap();

    HttpResponse::Ok().body(serialized)
}

/*
#[get("/delete/{id}")]
async fn Delete(path: web::Path<i32>) -> impl Responder {
    let id = path.into_inner();
}

 */

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .service(GetAll)
        })
        .bind(("127.0.0.1", 8088))?
        .run()
        .await
}