(*
 *
 * Copyright (c) 2002 by
 *  George C. Necula	necula@cs.berkeley.edu
 *  Scott McPeak        smcpeak@cs.berkeley.edu
 *  Wes Weimer          weimer@cs.berkeley.edu
 *  Simon Goldsmith     sfg@cs.berkeley.edu
 *
 * All rights reserved.  Permission to use, copy, modify and distribute
 * this software for research purposes only is hereby granted, 
 * provided that the following conditions are met: 
 * 1. XSRedistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice, 
 * this list of conditions and the following disclaimer in the documentation 
 * and/or other materials provided with the distribution. 
 * 3. The name of the authors may not be used to endorse or promote products 
 * derived from  this software without specific prior written permission. 
 *
 * DISCLAIMER:
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR 
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *)

(* libmaincil *)
(* this is a replacement for maincil.ml, for the case when we're
 * creating a C-callable library (libcil.a); all it does is register
 * a couple of functions and initialize CIL *)


module F = Frontc
module E = Errormsg

open Cil


(* print a Cil 'file' to stdout *)
let unparseToStdout (cil : file) : unit =
begin
  dumpFile defaultCilPrinter stdout cil
end;;

(* a visitor to unroll all types - may need to do some magic to keep attributes *)
class unrollVisitorClass = object (self)
  inherit nopCilVisitor

  (* variable declaration *)
  method vvdec (vi : varinfo) : varinfo visitAction = 
    begin
      vi.vtype <- unrollTypeDeep vi.vtype;
(*      ChangeTo vi *)
      SkipChildren
    end
    
  (* global: need to unroll fields of compinfo *)
  method vglob (g : global) : global list visitAction =
    begin
      match g with
          GCompTag(ci, loc) as g ->
            let doFieldinfo (fi : fieldinfo) : unit = 
              fi.ftype <- unrollTypeDeep fi.ftype 
            in begin                
                ignore(List.map doFieldinfo ci.cfields);
                (*ChangeTo [g]*)
                SkipChildren
              end              
        | _ -> SkipChildren
    end
end;;
let unrollVisitor = new unrollVisitorClass;;

(* open and parse a C file into a Cil 'file', unroll all typedefs *)
let parseOneFile (fname: string) : file =
  let ast = Frontc.parse fname () in
    begin
      visitCilFile unrollVisitor ast;
      ast
    end
;;

let getDummyTypes () : typ * typ =
  ( TPtr(TVoid [], []), TInt(IInt, []) )
;;

(* register some functions - these may be called form C code *)
Callback.register "cil_parse" parseOneFile;
Callback.register "cil_unparse" unparseToStdout;
Callback.register "unroll_type_deep" unrollTypeDeep;
Callback.register "get_dummy_types" getDummyTypes;

(* initalize CIL *)
initCIL ();


