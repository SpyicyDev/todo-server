use postgres::*;
use serde::{Serialize, Deserialize};



fn main() {
    let mut client = Client::connect("username = doadmin password = AVNS_AphIofhrOO6vcAN8gCP host = db-postgresql-nyc1-78249-do-user-7865624-0.b.db.ondigitalocean.com port = 25060 database = defaultdb sslmode = disable", NoTls).unwrap();

    let GET = client.prepare("SELECT * FROM todos").unwrap();
    let DELETE = client.prepare("DELETE FROM todos WHERE todo_id = $1").unwrap();
    let POST = client.prepare("INSERT INTO todos (todo_id, todo_text) VALUES ($1, $2)").unwrap();
}