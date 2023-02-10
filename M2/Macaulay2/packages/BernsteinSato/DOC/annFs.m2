doc ///
  Key
    AnnFs
    (AnnFs, RingElement)
    (AnnFs, List)
  Headline
    differential annihilator of a polynomial in a Weyl algebra
  Usage
    AnnFs(f)
    AnnFs(L)
  Inputs
    f:RingElement
      polynomial in a Weyl algebra $D$
    L:List
      of polynomials in the Weyl algebra $D$
  Outputs
     :Ideal
      the differential annihilator of $f$ in $D[s]$, for a new variable $s$, or the differential 
      annihilator of $L$ in $D[t_0,..,t_0,dt_0,..,dt_k]$, where $L$ is a list of $k+1$ elements 
      and the $t_i$ are new variables.
  Description
    Text
     This routine computes the ideal of the differential annihilator of a polynomial or list of 
     polynomials in a Weyl algebra $D$. This ideal is a left ideal of the ring $D[s]$ 
     or $D[t_0,..,t_k,dt_0,..,dt_k]$.  More
     details can be found in 
     [@HREF("https://mathscinet.ams.org/mathscinet/pdf/1734566.pdf","SST")@, Chapter 5].  
     The computation in the case of the element $f$ is via  Algorithm 5.3.6, and the computation
     in the case of the list $L$ is via the Algorithm 5.3.15.
    Example
      makeWA(QQ[x,y])
      f = x^2+y
      AnnFs f
    Example
      makeWA(QQ[x,y,z])
      L = {x^3,y+5*z}
  Caveat
     Must be over a ring of characteristic $0$.
///

-- FIXME: duplicate? which is newer?
-*
document {
     Key => AnnFs,
     Headline => "the annihilating ideal of f^s",
     "Either a single or a list of polynomials can be supplied for ",  EM "f", ".",
     SeeAlso => {"AnnIFs", "WeylAlgebra"}
     }

document {
     Key => {(AnnFs, RingElement)},
     Headline => "the annihilating ideal of f^s",
     Usage => "AnnFs f",
     Inputs => {
	  "f" => { 
	       "a polynomial in a Weyl algebra ", EM {"A", SUB "n"},  
	       " (should contain no differential variables)" 
	       }
	  },
     Outputs => {
	  Ideal => {"an ideal of ", EM {"A", SUB "n", "[s]"}}
	  },
     "The annihilator ideal is needed to compute a D-module 
     representation of the localization of ", 
     EM {"k[x", SUB "1", ",...,x", SUB "n", "]"}, " at ", EM "f", ".",
     EXAMPLE lines ///
     	  R = QQ[x_1..x_4, z, d_1..d_4, Dz, WeylAlgebra => toList(1..4)/(i -> x_i => d_i) | {z=>Dz}]
     	  f = x_1 + x_2 * z + x_3 * z^2 + x_4 * z^3
     	  AnnFs f
     	  ///,
     Caveat => {"The ring of ", TT "f", " should not have any parameters, 
     	  i.e., it should be a pure Weyl algebra. 
	  Also this ring should not be a homogeneous Weyl algebra."},
     SeeAlso => {"AnnIFs", "WeylAlgebra"}
     }  

document {
     Key => {(AnnIFs, Ideal,RingElement), AnnIFs}, 
     Headline => "the annihilating ideal of f^s for an arbitrary D-module", 
     Usage => "AnnIFs(I,f)",
     Inputs => {
	  "I" => {
	       "that represents a holonomic D-module", 
	       EM {"A", SUB "n", "/I"}
	       },
	  "f" => {"a polynomial in a Weyl algebra ", EM {"A", SUB "n"},  
	       " (should contain no differential variables)"}
	  },
     Outputs => {
	  Ideal => {"the annihilating ideal of ", TEX "A_n[f^{-1},s] f^s", " tensored with ",
	       TEX "A_n/I", " over the ring of polynomials" }
	  },
     EXAMPLE lines ///
	  W = QQ[x,dx, WeylAlgebra=>{x=>dx}]
	  AnnIFs (ideal dx, x^2)
	  ///, 
     Caveat => {"Caveats and known problems: The ring of f should not have any 
	  parameters: it should be a pure Weyl algebra. Similarly, 
	  this ring should not be a homogeneous Weyl algebra."
     	  },
     SeeAlso => {"AnnFs", "WeylAlgebra"}
     }  

document {
     Key => {(AnnFs, List)},
     Headline => "the annihilating ideal of f_1^{s_1}...f_r^{s_r}",
     Usage => "AnnFs F",
     Inputs => {
	  "F" => { 
	       "{f_1,...,f_r}, a list of polynomials in n variables                           
	       (f_i has to be an element of A_n, the Weyl algebra)"
	       }
	  },
     Outputs => {
	  Ideal => {"an ideal in A_n<t_1,..., t_r,dt_1,...,dt_r>"}
	  },
     EXAMPLE lines ///
     W = makeWA ( QQ[x_1..x_3] ) 
     AnnFs {x_2^2-x_1*x_3, x_1^3-x_3^2}
     ///,
     SeeAlso => {"AnnIFs", "WeylAlgebra"}
     }  
*-

doc ///
  Key
    diffRatFun
   (diffRatFun, List, RingElement)
   (diffRatFun, List, RingElement, RingElement, ZZ)
  Headline
    derivative of a rational function in a Weyl algebra
  Usage
    diffRatFun(m,f)
    diffRatFun(m,g,f,a)
  Inputs
    f:RingElement
      polynomial in a Weyl algebra $D$ in $n$ variables or ratinoal function in the fraction
      field of a polynomial ring in $n$ variables
    g:RingElement
      polynomial in a Weyl algebra $D$ in $n$ variables
    m:List 
      of nonnegative integers $m = \{m_1,...,m_n\}$
    a:ZZ
      an integer
  Outputs
     :RingElement
      the result of applying the product of the $(dx_i)^{m_i}$ to $f$ 
     :List
     -- (RingElement,RingElement,ZZ)
       the result of applying the product of the $(dx_i)^{m_i}$ to $g/f^a$, written as 
       (numerator,denominator,power of denominator)
  Description
    Text
     Let $D$ be a Weyl algebra in the variables $x_1,..x_n$ and partials $dx_1,..,dx_n$.  Let $f$ 
     be either a polynomial or rational function in the $x_i$ and $m = (m_1,..,m_n)$ a list 
     of nonnegative integers.  The function $f$ may be given as an element of a polynomial ring in the $x_i$
     or of the fraction field of that polynomial ring or of $D$.  This method applies the product of the 
     $dx_i^{m_i}$ to $f$. In the case of the input $(m,g,f,a)$, where $f \neq 0$ and $g$ are both 
     polynomials and $a$ is a nonnegative integer, it applies the product of the $dx_i^{m_i}$ to $g/f^a$ 
     and returns the resulting derivative as (numerator,denominator,power of denominator), not necessarily 
     in lowest terms.
    Example 
     QQ[x,y,z]
     m = {1,1,0}
     f = x^2*y+z^5
     diffRatFun(m,f)
    Example 
     makeWA(QQ[x,y,z])
     m = {1,1,0}
     f = x^2*y+z^5
     diffRatFun(m,f)
    Example
     frac(QQ[x,y])
     m = {1,2}
     f = x/y
     diffRatFun(m,f)
    Example
     makeWA(QQ[x,y,z])
     m = {1,2,1}
     g = z
     f = x*y
     a = 3
     diffRatFun(m,g,f,a)
  Caveat
    Must be over a ring of characteristic $0$.  
///

doc ///
  Key
    PolyAnn
   (PolyAnn, RingElement)
  Headline
    annihilator of a polynomial in the Weyl algebra
  Usage
    PolyAnn f
  Inputs
    f:RingElement
      polynomial
  Outputs
    :Ideal
      the annihilating (left) ideal of @{EM "f"}@ in the Weyl algebra
  Description
    Example
      makeWA(QQ[x,y])
      f = x^2-y^3
      I = PolyAnn f
  Caveat
    The input f should be an element of a Weyl algebra, and not an element of a commutative polynomial ring.
    However, f should only involve commutative variables.
  SeeAlso
    RatAnn
///

doc ///
  Key
    RatAnn
    (RatAnn, RingElement, RingElement)
    (RatAnn, RingElement)
  Headline
    annihilator of a rational function in Weyl algebra
  Usage
    RatAnn f
    RatAnn(g,f)
  Inputs
    f:RingElement
      polynomial
    g:RingElement
      polynomial
  Outputs
    :Ideal
      left ideal of the Weyl algebra
  Description
    Text
      @{TT "RatAnn f"}@ computes the annihilator ideal in the Weyl algebra 
      of the rational function $1/f$.
      @BR{}@
      @{TT "RatAnn(g,f)"}@ computes the annihilator ideal in the 
      Weyl algebra of the rational function $g/f$.
   Example
      makeWA(QQ[x,y])
      f = x^2-y^3
      g = 2*x*y
      I = RatAnn (g,f)
  Caveat
    The inputs f and g should be elements of a Weyl algebra, and not elements of a commutative polynomial ring.
    However, f and g should only use the commutative variables.
  SeeAlso
    PolyAnn
///
