module redis

#include <hiredis/hiredis.h>

const redis_conn_tcp  = C.redisConnectionType.REDIS_CONN_TCP
const redis_conn_unix = C.redisConnectionType.REDIS_CONN_UNIX

$if windows {
	
	const redis_sock_tcp  = C.tcp

	type connection_type = redis_conn_tcp
	type redis_sock      = redis_sock_tcp

} $else{

	const redis_sock_tcp  = C.tcp
	const redis_sock_unix = C.unix_sock

	type connection_type  = redis_conn_tcp | redis_conn_unix
	type redis_sock       = redis_sock_tcp | redis_sock_unix
}

struct DB{
mut:
	is_connected bool = false
	connector &C.redisConnect = unsafe { nil }
}

struct sock{
	socket redis_sock
	conn   connection_type
}

fn C.redisConnect(ip &const char, port int)                                        &C.redisContext;
fn C.redisConnectWithTimeout(ip const &&char, port int, tv const struct C.timeval) &C.redisContext;
fn C.redisConnectUnix(path const &&char)                                           &C.redisContext;
fn C.redisConnectUnixWithTimeout(path const &&char, tv const struct C.timeval)     &C.redisContext;

struct Config{
	timeout    C.timeval = -1
	sock_conn  sock
}

pub fn connect(config Config) {

	if config.timeout <= 0 {
		
		match config.sock_conn.conn {

			redis_conn_tcp {
				db := C.redisConnect(config.sock_conn.ip, config.sock_conn.port)
			}

			redis_conn_unix {
				db := C.redisConnectUnix(config.sock_conn.path)
			}
		}
	}else{

		match config.redis_conn {

			redis_conn_tcp {
				db := 	C.redisConnectWithTimeout(
							config.sock_conn.ip, 
							config.sock_conn.port, 
							config.timeout
						)
			}

			redis_conn_unix {
				db := 	C.redisConnectUnixWithTimeout(
							config.sock_conn.path, 
							config.timeout
						)
			}
		}
	}

	db is nil || db.err != 0 {
		return &SQLError{
			msg : db.errstr,
			code: db.err
		}
	}

	return DB{
		connector   : db
		is_connected: true
	}
}

fn (db &DB) close() {
	db.connector    = nil
	db.is_connected = false	
}

