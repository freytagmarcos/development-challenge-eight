package db

import (
	"database/sql"

	_ "github.com/lib/pq"

	"fmt"
	"os"
)

var (
	host     = os.Getenv("host")
	user     = os.Getenv("user")
	dbname   = os.Getenv("dbname")
	password = os.Getenv("password")
	port     = 5432
)

func ConectaComBancoDeDados() *sql.DB {
	conexao := fmt.Sprintf("host=%s port=%d user=%s dbname=%s password=%s sslmode=disable", host, port, user, dbname, password)
	db, err := sql.Open("postgres", conexao)

	if err != nil {
		panic(err.Error())
	}
	return db
}
