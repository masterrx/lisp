(defparameter *nodes* '((living-room (you are in the living-room.
                                          a wizard is snoring loudly on the couch.))
                        (garden (you are in a beatiful garden.
                                     	  there is a well in front of you.))
                        (attic (you are in the attic.
                        		          there is a giant welding torch in the corner.))))

(defparameter *edges* '((living-room (garden west door)
                                     (attic upstairs ladder))
                        (garden (living-room east door))
                        (attic (living-room downstairs ladder))))

(defparameter *objects* '(whiskey bucket frog chain))
(defparameter *object-locations* '((whiskey living-room)
                                   (bucket living-room)
                                   (chain garden)
                                   (frog garden)))

(defparameter *location* 'living-room)

(defparameter *allowed-commands* '(look walk pickup inventory))

(defun describe-location(location nodes)
  (cadr (assoc location nodes)))

(defun describe-path(edge)
	`(there is a ,(caddr edge) going ,(cadr edge) from here.))

(defun describe-paths(location edges)
  (apply #'append (mapcar #'describe-path(cdr(assoc location edges)))))

(defun objects-at(location objects object-locations)
  (labels ((at-loc-p (object)
                (eq (cadr (assoc object object-locations)) location)))
    (remove-if-not #'at-loc-p objects)))

(defun describe-objects(location objects object-locations)
  (labels ((describe-object (object)
                `(you see a ,object on the floor.)))  
  (apply #'append (mapcar #'describe-object(objects-at location objects object-locations)))))

(defun look()
  (append (describe-location *location* *nodes*)
  	      (describe-paths *location* *edges*)
  		  (describe-objects *location* *objects* *object-locations*)))

(defun walk(direction)
  (let ((next (find direction
                    (cdr (assoc *location* *edges*))
                    :key #'cadr)))
  (if next 
      (progn (setf *location* (car next))
             (look))
      '(You cannot go that way.))))

(defun pickup(object)
  (cond ((member object 
                 (objects-at *location* *objects* *object-locations*))
         (push (list object 'body) *object-locations*)
         `(you are now carrying the object))
  		 (t '(you cannot get that.))))

(defun inventory()
  (cons 'items(objects-at 'body *objects* *object-locations*)))

(defun have (object)
  (member object (cdr (inventory))))

(defparameter *chain-welded* nil)

(game-action weld chain bucket attic
             (if (and (have bucket)
                      (not *chain-welded*)
                      (progn (setf *chain-welded* 't)
                             '(the chain is now securely welded to the bucket.)))
                 '(You cannot weld like that)))

(defparameter *bucket-filled* nil)

(game-action dunk bucket well garden
          (if *chain-welded*
            (progn (setf *bucket-filled* 't)
                   '(the bucket is now full of water))
            '(the water level is too low to reach.)))

(defmacro game-action (command subj obj place &body body)
  `(progn (defun ,command (subject object)
            (if (and (eq *location* ',place)
                     (eq subject ',subj)
                     (eq object ',obj)
                     (have ',subj))
                ,@body
            '(i cannot command like that.)))
          (pushnew ',command *allowed-commands*)))

(game-action splash bucket wizard living-room
             (cond ((not *bucket-filled*) '(the bucket has nothin in it))
                   ((have 'frog ) '(the wizard awakens and sees that you stole his frog.
                                    he is so upset he banishers you to the netherworlds
                                    -you lose! The end.))
                   (t '(the wizard awakens from his slumber and greets you warmly.
                        he hands you the magic low-carb dobut - you win! the end.))))

(defun game-repl()
  (let ((cmd (game-read)))
    (print cmd)
    (unless (eq(car cmd) 'quit)
      (game-print (game-eval cmd))
      (game-repl))))

(defun game-read()
  (let ((cmd(read-from-string
              (concatenate 'string "(" (read-line) ")" ))))
    (flet ((quote-it (x)
                     (list 'quote x)))
          (cons (car cmd) (mapcar #'quote-it (cdr cmd))))))

(defun game-eval(sexp)
  (if (member (car sexp) *allowed-commands*)
      (eval sexp)
      '(Unknown command.)))

(defun tweak-text (lst caps lit)
  (when lst
  (let ((item (car lst))
    	(rest (cdr lst)))
  (cond ((eql item #\space) (cons item (tweak-text rest caps lit)))
        ((member item '(#\! #\? #\.)) (cons item (tweak-text rest t lit)))
        ((eql item #\") (tweak-text rest caps (not lit)))
        (lit (cons item (tweak-text rest nil lit )))
        (caps (cons (char-upcase item) (tweak-text rest nil lit)))        
  		(t (cons (char-downcase item) (tweak-text rest nil nil)))))))

(defun game-print (lst)
  (princ (coerce (tweak-text (coerce (string-trim "()" (prin1-to-string lst))
                                     'list)
                             t 
                             nil)
                 'string))
  (fresh-line))

(game-repl)

