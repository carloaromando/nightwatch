(local argparse (require :argparse))
(local sh (require :sh))
(local nn (require :nn))
;; todo remove
(local view (require :fennelview)) (global pp (fn [x] (print (view x))))

(local *pipe*    "ipc:///tmp/vg.ipc")
(local *range*   {:min 1000 :max 6500})
(local *channel* "foo")
(local *sct* (sh.command "sct"))

(var temp 6500)

(fn listen [s]
    (while true
      (let [data (s:recv 1024)]
        (print data))))

(fn connect-server []
    (doto (nn.socket nn.AF_SP nn.NN_SUB)
          (: :setopt nn.NN_SUB nn.NN_SUB_SUBSCRIBE *channel*)
          (: :connect *pipe*)))

(fn start-server []
    (*sct* temp)
    (listen (connect-server)))

(fn snd-cmd [cmd]
    (print (.. *channel* "|" cmd))
    (let [s (doto (nn.socket nn.AF_SP nn.NN_PUB)
              (: :bind *pipe*))]
      (let [(sent err) (s:send "foo|dsdddedd")]
        (s:send "foo|dsdddedd")
        (s:send "foo|dsdddedd")
        (print sent))))
      ;;     (sent err) (s:send (.. *channel* "|" cmd))]
      ;; (if err
      ;;     (print "Error"))))

(fn main [flag]
    (match flag
           {:start true} (start-server)
           {:inc   true} (snd-cmd :inc)
           _             (snd-cmd :dec)))

(let [parser (argparse :nightwatch "Nightwatch")]
  (parser:mutex
    (parser:flag "-s --start" "Start daemon")
    (parser:flag "-i --inc" "Increment temperature")
    (parser:flag "-d --dec" "Decrement temperature"))
  (main (parser:parse)))
    
