%%%

    title    = "The Ristretto Elliptic Curve Groups"
    abbrev   = "Ristretto"
    category = "info"
    docName  = "draft-ristretto-00"
    area     = "Internet"
    date     = 2018-07-25T23:00:00Z
    
    [[author]]
    initials     = "Dr. "
    surname      = "Who"
    fullname     = "Peter Wilton Cushing"
    role         = "editor"
    organization = "The Timelords"
    
    [[author]]
    initials     = "D.A.V.R.O.S."
    surname      = "Davros"
    fullname     = "Michael Wisher"
    role         = "editor"
    organization = "Imperial Daleks"

%%%

.# Abstract

This memo specifies two elliptic curves groups of prime order with
a high level of practical security in cryptographic applications.
These elliptic curve groups are intended to operate at the ~128-bit
and ~224-bit security level, respectively, and supplement the existing
elliptic curve groups specified in [@!RFC7748].

{mainmatter}

# Introduction

**Ristretto** is a technique for constructing prime order elliptic curve groups
with non-malleable encodings. It extends the [Decaf][decaf_paper] approach to cofactor
elimination to support cofactor-\\(8\\) curves such as Curve25519.

In particular, this allows an existing Curve25519 library to implement a
prime-order group with only a thin abstraction layer, and makes it possible
for systems using Ed25519 signatures to be safely extended with zero-knowledge
protocols, with **no additional cryptographic assumptions** and **minimal code
changes**.

Ristretto can be used in conjunction with Edwards curves with cofactor \\(4\\)
or \\(8\\), and provides the following specific parameter choices:

* `ristretto255`: Ristretto group for Curve25519;
* `ristretto448`: Ristretto group for Ed448-Goldilocks.

[decaf_paper]: https://eprint.iacr.org/2015/673.pdf

## Conventions Used in This Document

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [@!RFC2119].

# Background

Many cryptographic protocols require an implementation of a group of prime
order \\( \ell \\), usually an elliptic curve group.  However, modern elliptic curve
implementations with fast, simple formulas don't provide a prime-order group.
Instead, they provide a group of order \\(h \cdot \ell \\) for a small cofactor,
usually \\( h = 4 \\) or \\( h = 8\\).

In many existing protocols, the complexity of managing this abstraction is
pushed up the stack via ad-hoc protocol modifications.  But these modifications
are a recurring source of vulnerabilities and subtle design complications, and
they usually prevent applying the security proofs of the abstract protocol.

On the other hand, prime-order curves provide the correct abstraction, but
their formulas are slower and more difficult to implement in constant time.  A
clean solution to this dilemma is Mike Hamburg's [Decaf proposal][decaf_paper],
which shows how to use a cofactor-\\(4\\) curve to provide a prime-order group
– with no additional cost.

This provides the best of both choices: the correct abstraction required to
implement complex protocols, and the simplicity, efficiency, and speed of a
non-prime-order curve.  However, many systems use Curve25519, which has
cofactor \\(8\\), not cofactor \\(4\\).

**Ristretto** is a variant of Decaf designed for compatibility with
cofactor-\\(8\\) curves, such as Curve25519.  It is particularly well-suited
for extending systems using Ed25519 signatures with complex zero-knowledge
protocols.

## Pitfalls of a cofactor

Curve cofactors have caused several vulnerabilities in higher-layer protocol
implementations.  The abstraction mismatch can also have subtle consequences for
programs using these cryptographic protocols, as design quirks in the protocol
bubble up—possibly even to the UX level.

The malleability in Ed25519 signatures
[caused a double-spend vulnerability][monero]—or, technically, octuple-spend as
\\( h = 8\\)—in the CryptoNote scheme used by the Monero cryptocurrency, where
the adversary could add a low-order point to an existing transaction, producing
a new, seemingly-valid transaction.

In Tor, Ed25519 public key malleability would mean that every v3 onion service
has eight different addresses, causing mismatches with user expectations and
potential gotchas for service operators.  Fixing this required
[expensive runtime checks][bug22006] in the v3 onion services protocol,
requiring a full scalar multiplication, point compression, and equality check.
This check [must be called in several places][hs_address_is_valid] to validate
that the onion service's key does not contain a small torsion component.

[bug22006]: https://trac.torproject.org/projects/tor/ticket/22006#comment:13
[monero]: https://moderncrypto.org/mail-archive/curves/2017/000898.html
[hs_address_is_valid]: https://github.com/torproject/tor/search?q=hs_address_is_valid&amp;unscoped_q=hs_address_is_valid

## Disadvantages of multiplying by the cofactor

In some protocols, designers can specify appropriate places to multiply by the
cofactor \\(h\\) to "fix" the abstraction mismatches; in others, it's unfeasible
or impossible.  In any case, multiplying by the cofactor often means that
security proofs are not cleanly applicable.

As touched upon earlier, a curve point consists of an \\( h \\)-torsion
component and an \\( \ell \\)-torsion component.  Multiplying by the cofactor is
frequently referred to as "clearing" the low-order component, however doing so
affects the \\( \ell \\)-torsion component, effectively mangling the point.
While this works for some cases, it is not a validation method.
To validate that a point is in the prime-order subgroup, one can alternately
multiply by \\( \ell \\) and check that the result is
the identity.  But this is extremely expensive.

Another option is to mandate that all scalars have particular bit patterns, as
in X25519 and Ed25519.  However, this means that scalars are no longer
well-defined \\( \mathrm{mod} \ell \\), which makes HKD schemes
[much more complicated][hierarchical_keys].  Yet another approach is to
choose a [torsion-safe representative][torsion_safe]:
an integer which is \\( 0 \mathrm{mod} h \\) and with a particular value \\(
\mathrm{mod} \ell \\), so that scalar multiplications remove the low-order
component.  But these representatives are a few bits too large to be used with
existing implementations, and in any case aren't a comprehensive
solution.

[hierarchical_keys]: https://moderncrypto.org/mail-archive/curves/2017/000858.html
[torsion_safe]: https://moderncrypto.org/mail-archive/curves/2017/000866.html

# Definition

Ristretto is a construction of a prime-order group using a non-prime-order
Edwards curve.

The Decaf paper suggests using a non-prime-order curve \\(\\mathcal E\\) to
implement a prime-order group by constructing a quotient group.  Ristretto uses
the same idea, but with different formulas, in order to allow the use of
cofactor-\\(8\\) curves such as Curve25519.

Internally, a Ristretto point is represented by an Edwards point.  Two Edwards
points \\(P, Q\\) may represent the same Ristretto point, in the same way that
different projective \\( X, Y, Z \\) coordinates may represent the same Edwards
point.  Group operations on Ristretto points are carried out with no overhead
by performing the operations on the representative Edwards points.

To do this, Ristretto defines:

1. a new type for Ristretto points which contains the representative
   Edwards point;

2. equality on Ristretto points so that all equivalent
   representatives are considered equal;

3. an encoding function on Ristretto points so that all equivalent
   representatives are encoded as identical bitstrings;

4. a decoding function on bitstrings with built-in validation, so that only the
   canonical encodings of valid points are accepted;

5. a map from bitstrings to Ristretto points suitable for hash-to-point
   operations.

In other words, an existing Edwards curve implementation can implement the
correct abstraction for complex protocols just by adding a new type and three
or four functions.  Moreover, equality checking for the Ristretto group is
actually less expensive than equality checking for the underlying curve.

{backmatter}
