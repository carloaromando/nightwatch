(local argparse (require :argparse))
(local sh (require :sh))
(local socket-unix (require "socket.unix"))

(local *path*        "/tmp/nightwatch/")
(local *socket*      "ng.sock")
(local *socket-path* (.. *path* *socket*))
(local *range*       {:min 1000 :max 6500})
(local *sct*         (sh.command "sct"))

(var temp 6500)

(fn set-temp [t]
    (*sct* t)
    (set temp t))

(fn dec-temp []
    (let [tt (- temp 500)
          t  (if (<= tt (. *range* :min))
               (. *range* :min)
               tt)]
      (set-temp t)))

(fn inc-temp []
    (let [tt (+ temp 500)
          t  (if (>= tt (. *range* :max))
               (. *range* :max)
               tt)]
      (set-temp t)))

(fn listen [s]
    (while true
      (let [data (: s :receive)]
        (print (.. "Received " data " cmd"))
        (match data
               :inc (inc-temp)
               _    (dec-temp)))))

(fn check-path []
    (let [response (os.execute (.. "cd " *path*))]
      (if (~= response nil)
          ((sh.command "rm" "-rf") *path*))
      ((sh.command "mkdir")  *path*)))    

(fn connect-server []
    (check-path)
    (let [s (socket-unix.dgram)
          (status err) (: s :bind *socket-path*)]
      (if err
          (do
           (print (.. "[Connection error] " err))
           (os.exit))
          s)))

(fn start-server []
    (*sct* temp)
    (listen (connect-server)))

(fn snd-cmd [cmd]
    (print (.. "Sending command " cmd))
    (doto (socket-unix.dgram)
          (: :connect *socket-path*)
          (: :send cmd)))

(fn main [flag]
    (match flag
           {:dec true} (snd-cmd :dec)
           {:inc true} (snd-cmd :inc)
           _           (start-server)))

(let [parser (argparse :nightwatch "Nightwatch")]
  (: parser :mutex
    (: parser :flag "-s --start" "Start daemon")
    (: parser :flag "-i --inc" "Increment temperature")
    (: parser :flag "-d --dec" "Decrement temperature"))
  (main (: parser :parse)))
    
