((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,G,B={
bB(d){var x=$.nf.k(0,d)
if(x==null){x=new B.eV(d,A.f([],y.C))
$.nf.i(0,d,x)}return x},
eW:function eW(d){this.b=d},
de:function de(d,e){this.c=d
this.a=e},
hi:function hi(d,e,f,g,h,i,j){var _=this
_.d$=d
_.e$=e
_.f$=f
_.cy=null
_.db=g
_.c=_.b=_.a=null
_.d=h
_.e=null
_.f=i
_.w=_.r=null
_.x=j
_.Q=_.z=_.y=null
_.as=!1
_.at=!0
_.ax=!1
_.CW=null
_.cx=!1},
b5:function b5(d,e,f){var _=this
_.w=d
_.x=e
_.y=null
_.z=f
_.d=$
_.c=_.b=_.a=null},
eV:function eV(d,e){var _=this
_.a=d
_.e=_.d=_.c=_.b=$
_.f=e
_.r=!0},
ig:function ig(){},
ix:function ix(d){this.b=d},
fp:function fp(d,e){this.c=d
this.a=e},
h0:function h0(d,e){this.c=d
this.a=e},
cM:function cM(d){this.a=d},
h3:function h3(){this.d=!1
this.c=this.a=null},
jQ:function jQ(d){this.a=d},
jP:function jP(d){this.a=d},
qr(d){var x,w,v=y.w,u=A.L(v,v)
for(x=0;x<A.U(d.length);++x){w=A.y(d.item(x))
u.i(0,A.v(w.name),A.v(w.value))}return u},
tT(d){return new B.cM(null)}},E,K,H,F,L,M,D,I
A=c[0]
C=c[2]
G=c[12]
B=a.updateHolder(c[6],B)
E=c[24]
K=c[13]
H=c[17]
F=c[19]
L=c[16]
M=c[18]
D=c[15]
I=c[9]
B.eW.prototype={
aK(){return"AttachTarget."+this.b}}
B.de.prototype={
aq(){var x=A.dr(y.b),w=($.af+1)%16777215
$.af=w
return new B.hi(null,!1,!1,x,w,this,C.j)}}
B.hi.prototype={
bM(){var x=this.f
x.toString
y.h.a(x)
return E.an},
az(){var x,w,v=this.f
v.toString
y.h.a(v)
x=this.e
x.toString
x=new B.b5(A.f([],y.k),E.q,x)
x.bz("")
w=B.bB(x.x)
C.b.m(w.f,x)
w.r=!0
x.se8(v.c)
return x},
al(d){var x
y.n.a(d)
x=this.f
x.toString
y.h.a(x)
d.shW(E.q)
d.se8(x.c)},
bb(){var x,w
this.di()
x=this.d$
x.toString
y.n.a(x)
w=this.e
w.toString
x.shj(w)},
aA(){var x,w
this.eX()
x=this.d$
x.toString
y.n.a(x)
w=B.bB(x.x)
C.b.I(w.f,x)
w.aW()}}
B.b5.prototype={
shW(d){var x=this,w=x.x
if(w===d)return
w=B.bB(w)
C.b.I(w.f,x)
w.aW()
x.x=d
w=B.bB(d)
C.b.m(w.f,x)
w.r=!0
B.bB(x.x).aW()},
se8(d){y.f.a(d)
if(this.y===d)return
this.y=d
B.bB(this.x).aW()},
shj(d){if(this.z===d)return
this.z=d
B.bB(this.x).ez(!0)},
aM(d,e){var x,w,v,u,t=this
d.a=t
try{x=d.gT()
w=e==null?null:e.gT()
if(w==null&&C.b.H(t.w,x))return
if(w!=null&&!C.b.H(t.w,w))w=null
v=t.w
C.b.I(v,x)
u=w!=null?C.b.aD(v,w)+1:0
C.b.ej(v,u,x)
B.bB(t.x).aW()}finally{d.aB()}},
I(d,e){C.b.I(this.w,e.gT())
e.a=null
B.bB(this.x).aW()}}
B.eV.prototype={
gee(){var x,w=this,v=w.b
if(v===$){x=A.y(A.j(b.G.document).querySelector(w.a.b))
x.toString
w.b!==$&&A.md()
w.b=x
v=x}return v},
ez(d){var x,w,v,u,t,s,r,q,p,o,n,m=this
if(d||m.r){C.b.an(m.f,new B.ig())
m.r=!1}x=m.c
if(x===$){w=B.qr(A.j(m.gee().attributes))
m.c!==$&&A.md()
m.c=w
x=w}for(v=m.f,u=v.length,t=0;t<v.length;v.length===u||(0,A.aP)(v),++t){s=v[t].y
if(s!=null)x.S(0,s)}r=A.ms(y.w)
for(q=0;v=m.gee(),q<A.U(A.j(v.attributes).length);++q)r.m(0,A.v(A.y(A.j(v.attributes).item(q)).name))
if(x.a!==0)for(u=new A.ay(x,A.i(x).h("ay<1,2>")).gv(0);u.p();){p=u.d
o=p.a
A.eX(v,o,p.b)
r.I(0,o)}if(r.a!==0)for(u=A.nT(r,r.r,r.$ti.c),o=u.$ti.c;u.p();){n=u.d
if(n==null)n=o.a(n)
v.removeAttribute(n)}},
aW(){return this.ez(!1)}}
B.ix.prototype={
aK(){return"Display."+this.b}}
B.fp.prototype={
W(d){var x=y.F
return new I.ci(this.c,A.f([D.b3(A.f([],x),"M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z")],x),null)}}
B.h0.prototype={
W(d){var x=null,w=y.F,v=A.f([],w),u=y.w
u=A.L(u,u)
u.i(0,"cx","12")
u.i(0,"cy","12")
u.i(0,"r","4")
return new I.ci(this.c,A.f([new F.ac("circle",x,x,x,u,x,v,x),D.b3(A.f([],w),"M12 4h.01"),D.b3(A.f([],w),"M20 12h.01"),D.b3(A.f([],w),"M12 20h.01"),D.b3(A.f([],w),"M4 12h.01"),D.b3(A.f([],w),"M17.657 6.343h.01"),D.b3(A.f([],w),"M17.657 17.657h.01"),D.b3(A.f([],w),"M6.343 17.657h.01"),D.b3(A.f([],w),"M6.343 6.343h.01")],w),x)}}
B.cM.prototype={
bc(){return new B.h3()}}
B.h3.prototype={
bf(){this.cc()
this.d=A.aO(A.y(A.j(b.G.document).documentElement).getAttribute("data-theme"))==="dark"},
W(d){var x,w=this,v=null,u=y.F,t=A.f([],u),s=w.d?"dark":"light",r=y.w
t.push(new B.de(A.ba(["data-theme",s],r,r),v))
r=A.ba(["aria-label","Theme Toggle"],r,r)
s=F.hO(v,v,w.d?E.x:v,v,v,v,v,v,v,v,v)
s=G.da(A.f([new B.fp(20,v)],u),s)
x=F.hO(v,v,w.d?v:E.x,v,v,v,v,v,v,v,v)
t.push(L.mU(A.f([s,G.da(A.f([new B.h0(20,v)],u),x)],u),r,"theme-toggle",v,new B.jQ(w),v))
return new K.c0(t,v)}}
var z=a.updateTypes(["d(b5,b5)"])
B.ig.prototype={
$2(d,e){var x=y.n
x.a(d)
x.a(e)
return d.z-e.z},
$S:z+0}
B.jQ.prototype={
$0(){var x,w=this.a
w.am(new B.jP(w))
x=A.j(A.j(b.G.window).localStorage)
w=w.d?"dark":"light"
x.setItem("jaspr:theme",w)},
$S:0}
B.jP.prototype={
$0(){var x=this.a
x.d=!x.d},
$S:0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(A.cT,[B.eW,B.ix])
w(B.de,A.o)
w(B.hi,A.bq)
w(B.b5,A.dk)
w(B.eV,A.h)
w(B.ig,A.bk)
x(M.ai,[B.fp,B.h0])
w(B.cM,H.aA)
w(B.h3,H.a4)
x(A.b6,[B.jQ,B.jP])})()
A.b_(b.typeUniverse,JSON.parse('{"b5":{"aI":[],"mv":[],"cH":[]},"de":{"o":[]},"hi":{"an":[],"l":[],"ab":[]},"fp":{"ai":[],"o":[]},"h0":{"ai":[],"o":[]},"cM":{"aA":[],"o":[]},"h3":{"a4":["cM"],"a4.T":"cM"}}'))
var y={h:A.r("de"),n:A.r("b5"),b:A.r("l"),C:A.r("t<b5>"),F:A.r("t<o>"),k:A.r("t<p>"),w:A.r("c"),f:A.r("x<c,c>?")};(function constants(){var x=a.makeConstList
E.q=new B.eW("html")
E.x=new B.ix("none")
E.an=x([],y.F)})();(function staticFields(){$.nf=A.L(A.r("eW"),A.r("eV"))})()};
(a=>{a["flKEDGfhnyHE5GIWyIJaSFbtG5k="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.clients.dart.js_15.part.js.map
