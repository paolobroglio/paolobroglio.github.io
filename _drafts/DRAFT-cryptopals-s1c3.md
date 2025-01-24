---
layout: post
title:  "Cryptopals - Set 1 - Single-byte cipher"
tags: ["cryptography", "challenges", "go"]
---

If you read [my previous post]({% post_url _posts/2025-01-22-cryptopals-s1c1 %}) you probably noticed that the solution is mostly based on the official 
Base64 encoding RFC. This is quite interesting because there's no need to rely on any RFC, but instead is a real problem solving challenge and it's about decrypting an encrypted text. Some knowledge of the previous post might be useful for completing this challenge, especially the bitwise operations.

## The problem

The challenge says that we have a hex encoded string

```
1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736
```

That has ben XOR'd against a single character. We are being asked to find the key. 

Then there's an additional hint:

> Devise some method for "scoring" a piece of English plaintext. **Character frequency is a good metric**. Evaluate each output and choose the one with the best score.

Basically what we need to do is:

- Find a subset of the English alphabet that contains only **most frequent letters**
- Perform a XOR against each of those letters' byte representation and find out which one was used during the encrypting phase

## Solution

Since the cipher revolves around a XOR operation we can tackle that first and then we can move on to the logic itself. 

### How XOR works

#### XOR

**XOR (exclusive OR)** is a logical operation that compares two binary inputs and produces a result based on the following rule:

- The output is **true (1)** if the inputs are **different** (one is 1 and the other is 0).
- The output is **false (0)** if the inputs are **the same** (both are 0 or both are 1).

The truth table for XOR:

| Input A | Input B | Output (A XOR B) |
|---------|---------|------------------|
|    0    |    0    |        0         |
|    0    |    1    |        1         |
|    1    |    0    |        1         |
|    1    |    1    |        0         |

#### Usage in cryptography

XOR is a fundamental operation in many cryptographic algorithms, such as:

- **Stream ciphers**, where plaintext is XORed with a pseudorandom keystream.
- **Block ciphers**, where XOR is used in modes like [[CBC|Cipher Block Chaining]] (Cipher Block Chaining) for chaining blocks of ciphertext together.

Its efficiency and security level makes it a useful component in the cryptography world

XOR is also a reversible operation: applying XOR twice with the same key returns the original data.

- Example: If `C = P XOR K` (ciphertext = plaintext XOR key), then:
    - Decryption: `P = C XOR K` (plaintext = ciphertext XOR key).

### Approaching the solution

We're gonna use XOR's **reversible property** to solve the challenge. 

Basically we will apply the `P = C XOR K` formula where `K` will be one of the most frequent letters used in the English alphabet.

We'll try each letter and by taking a look at the plaintext we will understand which one of the letters is the actual key, because every decryption done with the wrong key will return a meaningless plaintext.

### Utility functions

The first thing to do is to create a function that perform the XOR between the input string and a single byte.

We can start by re-using the utility function created for the first challenge that creates a byte array starting from a string.

```go
func ConvertHexStringToByteArray(hexString string) ([]byte, error) {
  byteArray := make([]byte, len(hexString)/2)
    for i := 0; i < len(hexString); i += 2 {
      b, err := strconv.ParseUint(hexString[i:i+2], 16, 8)
	  if err != nil {
		return nil, err
	  }
      byteArray[i/2] = byte(b)
    }
  return byteArray, nil
}
```

### The cipher itself

XOR operation is done by using the `^` operator. 
Then we can apply the formula is the one that has been presented above `P = C XOR K` . 
Doing this for every byte that compose the data will do the trick.

```go
decoded := make([]byte, len(data))
for i := 0; i < len(data); i++ {
  decodedByte := data[i] ^ key
  decoded[i] = decodedByte
}
```

We can see the result by applying a formatting function like 

```go
fmt.Printf("Decryption result: %s\n", string(res))
```

And see if the decryption result is meaningful or not.

A trivial way of completing this challenge is to call the decode logic on each most frequent letter resulting in a simple for loop. But we can write a faster solution by leveraging Go routines and wait groups.

### Enter the Goroutines

We're gonna lightweight threads that in Go are called *goroutines* so we can try to decode the string against each frequent letter in a parallel way.

In order to achieve this we also need a `WaitGroup`. This is a structure that is used to check if a collection of goroutines has finished its work. This quotation is taken from [Go sync package documentation](https://pkg.go.dev/sync#example-WaitGroup)

> The main goroutine calls [WaitGroup.Add](https://pkg.go.dev/sync#WaitGroup.Add) to set the number of goroutines to wait for. Then each of the goroutines runs and calls [WaitGroup.Done](https://pkg.go.dev/sync#WaitGroup.Done) when finished. At the same time, [WaitGroup.Wait](https://pkg.go.dev/sync#WaitGroup.Wait) can be used to block until all goroutines have finished.

We also need a [channel](https://go.dev/tour/concurrency/2) where we can store each goroutine's result.

We can start by declaring the WaitGroup and the channel

```go
var wg sync.WaitGroup
results := make(chan []byte
```

Then we loop over the most frequent letters collection and:
- Add 1 to the WaitGroup since we're spawning a new goroutine
- Spawn a new goroutine that computes the XOR against the current letter and puts the result inside the `results` channel

```go
for _, letterFrequency := range lettersFrequencies {
  wg.Add(1)
  key := []byte(string(letterFrequency))
  go func() {
    defer wg.Done()
    data, _ := SingleByteXORCipher(input, key[0])
    results <- data
  }()
}
```

Then we spawn a new goroutine *outside* the for loop that will be waiting until the `WaitGroup` counter will be brought down to 0, meaning that each goroutine has completed its work.

```go
go func() {
  wg.Wait()
  close(results)
}()
```

Finally we reach the point where each goroutine has finished and the `results` channel is available to be consumed.

```go
for res := range results {
 fmt.Printf("Decrypted: %s\n", string(res))
}
```

## Outcome

Here's the output of this solution. Of course, depending on how many letters you consider you will be having a longer or shorter output. 

```
Deciphered: Zvvrpw~9TZ>j9upr|9x9ivlw}9v9{xzvw
Deciphered: ^rrvtsz=P^:n=qtvx=|=mrhsy=r{=|~rs
Deciphered: W\{\{\}zs4YW3g4x}q4u4d{azp4{r4vuw{z
Deciphered: Ieeacdm*GI-y*fcao*k*zedn*el*hkied
Deciphered: R~~zxv1\R6b1}xzt1p1a~du1~w1spr~
Deciphered: Txx|~yp7ZT0d7{~|r7v7gxbys7xq7uvtxy
Deciphered: Occgebk,AO+,`egi,m,|cybh,cj,nmocb
Deciphered: Uyy}xq6[U1e6z}s6w6fycxr6yp6twuyx
Deciphered: Hdd`bel+FH,x+gb`n+j+{d~eo+dm+ijhde
Deciphered: Vzz~|{r5XV2f5y|~p5t5ez`{q5zs5wtvz{
Deciphered: Xttpru|;VX<h;wrp~;z;ktnu;t};yzxtu
Deciphered: _sswur{<Q_;o<puwy<}<lsirx<sz<~}sr
Deciphered: Kggcafo(EK/{(dacm(i(xg}fl(gn(jikgf
Deciphered: L``dfah/BL(|/cfdj/n/`zak/`i/mnl`a
Deciphered: S{y~w0]S7c0|y{u0q0`e~t0v0rqs~
Deciphered: \pptvqx?R\8l?svtz?~?opjq{?py?}~|pq
Deciphered: Yuuqst}:WY=i:vsq:{:juot~:u|:x{yut
Deciphered: ]qquwpy>S]9m>rwu{>>nqkpz>qx>|}qp
Deciphered: Bnnjhof!LB&r!mhjd!`!qntoe!ng!c`bno
Deciphered: Ammikle"OA%q"nkig"c"rmwlf"md"`caml
Deciphered: P||xz}t3^P4`3zxv3r3c|f}w3|u3qrp|}
Deciphered: Maaeg`i.CM)}.bgek.o.~a{`j.ah.loma`
Deciphered: Cooking MC's like a pound of bacon
Deciphered: Jffb`gn)DJ.z)e`bl)h)yf|gm)fo)khjfg
Deciphered: Q}}y{|u2_Q5a2~{yw2s2b}g|v2}t2psq}|
```

In fact the challenge tells about a set of letters that is usually used to perform a check based on frequency

> "ETAOIN SHRDLU"

Which is also a famous joke, [read more of this on Wikipedia](https://en.wikipedia.org/wiki/Etaoin_shrdlu)

# Wrapping up

- XOR is widely used in cryptography as an efficient and reliable way to encrypt plaintexts. It's also quite easy to understand and to apply.
- Alphabet letters frequency is a good starting point when trying to investigate on such simple ciphered texts. This is also the most common method used in decrypting the famous [Caesar cipher](https://en.wikipedia.org/wiki/Caesar_cipher)
- Goroutines are great for achieving parallel computation using lightweight threads

# Useful resources

- [Single-byte XOR cipher challenge](https://cryptopals.com/sets/1/challenges/3)
- [Go WaitGroup](https://pkg.go.dev/sync#example-WaitGroup)
- [Go channels](https://go.dev/tour/concurrency/2)
- [ETAOIN SHRDLU](https://en.wikipedia.org/wiki/Etaoin_shrdlu)
- [Caesar cipher](https://en.wikipedia.org/wiki/Caesar_cipher)