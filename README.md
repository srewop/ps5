Problem Set 4: Password Cracking
================================
*Computer Programming for Lawyers - Fall 2024*

Introduction
------------

On this assignment, you will explore several techniques for cracking passwords
in order to gain a deep technical understanding of state-of-the-art measures for
storing passwords securely.
In doing so, you will demonstrate that you are familiar with lists, strings,
for-loops, and iteration.

Your assignment repository contains the following files:
* `cplhash.py` (library with two hash functions)
* `words.txt` (around 10,000 of the most popular English language words)
* `passwords.txt` (around 10,000 of the most popular passwords found on a breached website)

Expectations
------------
* This is an individual assignment. The standard course collaboration policy applies.
* You are permitted to use only the Python features we have covered so far (Chapters 1-9).
* You should use effective programming style. A portion of your grade will be
determined by your programming style.
  * Please continue to adhere to the [_Style Guide_ on GitHub](https://github.com/Computer-Programming-for-Lawyers/Fall-2024/blob/main/style-guide.md).
  * Remember to include headers in all of your programs.
  * Style is inherently subjective. Use your best judgment and emulate the style from the
    textbook. When in doubt, ask on Ed.

Summary of Tasks
----------------
* Build and submit file `hash_collisions.ipynb`
* Build and submit file `dictionary_attack.ipynb`
* Build and submit file `brute_force.ipynb`

As a reminder, there is no formal 'submit' button on GitHub Classroom. As long as you complete your work in Codespaces and commit and push your work once complete, we will be able to see your final product. For a reminder on how to commit and push your work, see the file `codespaces-instructions.md` (as a reminder, you can open this file by clicking on it in the file explorer, or by entering `code codespaces-instructions.md` into the terminal).

Start Early
-----------

You know the drill at this point. Please start early. You'll be glad you did.


Important Warnings
------------------

* Although the steps we are teaching you below are a bit stylized and simplified to make sense as a problem set,
we are teaching you a key password-cracking technique used for evil by computer criminals and for good by computer security professionals.
We urge you to use these new skills only for good and never evil. If you need a good reason (other than your own
moral conscience) to listen to this advice, the
unauthorized use of another person's password might lead you to become the target of a criminal investigation.
We neither condone nor authorize password cracking on production systems.

* As usual, make sure your programs behave in a manner identical to our example prompts.

Roadmap
-------

This problem set is going to be a little different. The last
two problem sets were a grab bag of toy examples meant to assess your mastery
of basic Python. This problem set tells the story of password cracking.

*You will be asked to complete three tasks. Each task is worth one-third of the total possible points for the
assignment (excluding style points).*

***

Hash Functions
==============

The core technology at the heart of this problem set is an ingenious type of computational function called a *hash function*. A hash function uses a series of mathematical operations to transform a string of any size (like `'Hello, world!'`) into a random-looking string of a fixed size (like `'6cd3556deb0da54bca060b4c39479839'`). This is what a hash function looks like in practice:

```python
import cplhash
cplhash.md5_hash('hi')
```
'49f68a5c8493ec2c0bf489821c21fc3b'

```python
cplhash.md5_hash('Hello, world!')
```
'6cd3556deb0da54bca060b4c39479839'
```python
cplhash.md5_hash('I love computer programming for lawyers')
```
'9adf42d868c9cffc3f6469fa842e11e5'


The python function `cplhash.md5_hash()` is a hash function which takes a string as input and produces 32 letters or numbers of seeming gibberish as output. (It implements what is known as the MD5 hash algorithm; thus the name.) We call these outputs *hash values* or, simply, *hashes*. Hash functions have some very useful properties that allow them to be used to solve otherwise very difficult problems. The two most important properties for our purposes are:

1. *Repeatability*: A given hash function will always return precisely the same hash value for a given input. In the example above, the `md5_hash()` value of `'hi'` will always be `49f68a5c8493ec2c0bf489821c21fc3b`.

2. *One-Way*: Your computer can generate a hash value for a given input *efficiently*, meaning without using much time, processing power, or memory. But hash functions are designed to make it computationally *inefficient* or *infeasible* to reverse a hash value. Given a particular hash value, it is very, very, very difficult to find a corresponding input string that generates that value. For purposes of our class, you should consider the reverse function not only difficult, but essentially impossible. In other words, if we told you the output of `md5_hash()` was `'23eeeb4347bdd26bfc6b7ee9a3b755dd'`, you would have no way to know that the input was `'python'`. The only way to find out would be to try every possible string until you found a match, which is impossibly slow in practice.

It may not yet be obvious how, but these two properties in tandem--repeatability and one-way-ness--can be combined to solve many very difficult problems. In this problem set, we'll look at how hash functions figure into password security.

A note about how to calculate a hash value: We have provided you with a convenient Python library called `cplhash.py` that contains the hash functions you will need for this assignment. The file contains two hash functions, `cplhash.md5_hash()` and `cplhash.short_hash()`. The `cplhash.md5_hash()` function takes a string as its argument and produces a 32-character hash using the MD5 algorithm. The `cplhash.short_hash()` function produces a 3-character hash, which is not something you would want to do in practice, but which we are doing to make one of the tasks possible. Because `cplhash.py` is in the same directory as your program, you can "call" its functions once you add `import cplhash` to the beginning of a `.py` file. After that, you can call `cplhash.md5_hash()` and `cplhash.short_hash()` as desired. Here's an example:
   
   ```python
   import cplhash
   cplhash.md5_hash('hello')
   ```
   '5d41402abc4b2a76b9719d911017c592'
   ```python
   cplhash.short_hash('hello')
   ```
   '5d4'
   
Before you read further, you might play with these two functions. Try passing various strings to these functions and comparing the hashes that result. How do the hash values for two very similar strings (say differing by only a single character) compare to one another? Can you find two strings that produce the same hash value using `cplhash.md5_hash()`? (If you can, please email us right away!) How about using `cplhash.short_hash()`? 

***


Password Cracking
=================

Background
----------
Digital information is easy to aggregate, store, and access, a fact we enjoy every day
as we browse the news online or search StackOverflow for help with Python. Unfortunately,
this convenience also makes data easy to steal. To keep digital resources safe, we typically lock them in such a way that
only legitimate users can access them. But how do we know whether someone is a "legitimate user"?
Security experts usually group methods for doing so into three categories:
* Something you know (passwords, security questions)
* Something you have (smartphones - two factor authentication, a special token to read off or plug into your computer)
* Something you are (fingerprints, iris scans, facial recognition)

As you're no-doubt aware, passwords are the most popular option. They are cheap to implement,
difficult to steal (since, ideally, the only place they're stored is in your head),
and easy to change if they are lost.

Storing Passwords
-----------------
Imagine you're running a website like Twitter or Facebook. You have hundreds of millions of users,
each of whom has a username and a password. How do you store the passwords? At first, you might just
stick all of the passwords in a file, unaltered in "plain text". When a user tries to log in, all you need to do
is make sure the password she supplies matches the one you have on file.

As it turns out, this strategy is very insecure. What if your website were to be the victim of a data breach?
An attacker has just stolen the file containing all of your users' passwords, granting access to every single account on your site.
Worse, users tend to reuse passwords across sites, so it's very likely that the suffering won't
be confined to your site alone.

In practice, websites never store the passwords in plain text.
Instead, they store the hash values corresponding to their users' passwords. Why does this improve security?

If your password is `'123456'`, a website stores the value returned by the function `cplhash.md5_hash('123456')`, or `e10adc3949ba59abbe56e057f20f883e`. Whenever you try to log in, the website takes the hash of the guess you've provided and checks whether it matches the hash of your password. In other words, it tests whether `cplhash.md5_hash(guessed_password) == cplhash.md5_hash(actual_password)`. This way, the website only ever needs to store `cplhash.md5_hash(actual_password)` rather than `actual_password` itself.
   
If an attacker were to steal the website's password file, she would get only the hashes. She would know that a user had been using a password that corresponds to the hash value `e10adc3949ba59abbe56e057f20f883e`, but she wouldn't know the password itself. She'd have to find the inputs that produced those hashes to actually get any passwords, a task we've already said is nearly impossible thanks to the one-way property of hash functions.

Task 1: hash_collisions.ipynb
-------------------------

*This task is worth one-third of the total possible points (excluding style points).*

You may have noticed that a hash function always produces an output of the same length (32 characters
for `cplhash.md5_hash`) no matter how long its input. You could give it a very long input (say,
all of *War and Peace*) and it would still output a 32-character string.
This means that there exist more possible inputs
that you could give to `cplhash.md5_hash()` than there are outputs it can produce. If you
try hard enough, you will eventually find two inputs for which `cplhash.md5_hash()` produces the same output.
This is called a *hash collision*. Why are hash collisions bad? If you store the hashes of your users'
passwords, it's possible that someone could type the wrong password but still log in if the hashes happen
to collide. Hashes appear in a number of other security-sensitive settings (like sending encrypted
messages) where collisions would be disastrous.

For your first task, we will give you a text file containing a list of words.
**Your program, `cplhash_collisions.ipynb`, will take as inputs the name of this text file
and one additional word. Your program should create a Python list of all
of the words from the file that have the same hash
as the additional word. It should then print the words in this list in alphabetical order.**

```
Word file: 𝘄𝗼𝗿𝗱𝘀.𝘁𝘅𝘁
Collisions for: 𝗺𝗶𝗹𝗹𝗮𝗿𝗱
complaint
informational
street
```

```
Word file: 𝘄𝗼𝗿𝗱𝘀.𝘁𝘅𝘁
Collisions for: 𝘄𝗼𝗼𝗱𝗿𝗼𝘄
daughter
were
```

```
Word file: 𝘄𝗼𝗿𝗱𝘀.𝘁𝘅𝘁
Collisions for: 𝗴𝗿𝗼𝘃𝗲𝗿
atomic
clara
computational
eternal
```

**Any loops you use must be for-loops. Since this file relies on `cplhash.py` to work, make sure
to add it to the list of dependencies in the header.**

Before you can get started on this program, you'll need to know one more helpful bit of Python: The file `words.txt` (like its sister file, `passwords.txt`, which we'll use later) contains one word per line. To read a file structured in this fashion into a list of words, you can use the following commands:
   
   ```python
   >>> filename = 'words.txt'
   >>> word_list = open(filename).read().split('\n')
   >>> word_list
   ['the', 'of', 'and', 'to', ...]
   ```
   
By this point in the semester, the second command should no longer be a complete mystery. The `open()` function opens the file named by its argument. The `read()` method reads the contents of the opened file into a string. As you learned this week, the `split()` function divides a long string into a list of shorter strings, splitting every time the argument appears. Since we gave `split()` the argument `'\n'`, it will divide the string every time it sees a new line. We'll revisit the `open()` and `read()` functions in depth later in the semester.

**For Task 1, you are required to use `cplhash.short_hash()` to look for hash collisions.** You wouldn't have found 
any collisions if you had used `cplhash.md5_hash()`, which is far stronger. (But read the epilogue for more on md5!)
**This is the only Task in this problem set that requires the `cplhash.short_hash()` function.
Use `cplhash.md5_hash()` for Tasks 2 and 3.**
   

Cracking Passwords
------------------

For your next tasks, you will put yourself in the shoes of an attacker.
Although doing so may feel uncomfortable, security experts design systems by planning for
the worst-case attacker. Only by understanding the attacker's perspective can you develop
effective countermeasures.

Suppose you have compromised a password database. You now have a long list of hashes, and you're eager to determine the corresponding passwords. As we mentioned before, it's nearly impossible to determine the input that a hash function used to produce a specific output.

Passwords, however, are not any random input. Some passwords are far more common than others.
For example, past data breaches have shown that users tend to overuse passwords like `123456` and
`password1`. To reverse many hashed passwords, we can make educated guesses about the kinds of passwords people are
most likely to choose.

Two popular approaches for identifying passwords associated with particular hashes are so-called *dictionary attacks*
and *brute-force attacks*. You will implement one of each type in the tasks that follow.

Task 2: dictionary_attack.ipynb
----------------------------

*This task is worth one-third of the total possible points (excluding style points).*

A dictionary attack is quite simple: try to break a hash using passwords that are known to be popular. People
tend to use a small set of weak, common passwords typically derived from words in the English language,
so dictionary attacks usually reverse a large number of hashes. 

All you need is a list of commonly used passwords. Researchers have collected these, a silver-lining byproduct of massive data breaches,
offering valuable insight into the way users create passwords. We have included
almost 10,000 of the most common passwords from a past data breach in the "dictionary file" `passwords.txt` and almost 10,000 of the most popular words in the English language in `words.txt`. Attempting a dictionary attack using either database is likely 
to be fruitful. You just need to convert each candidate password into a hash value and then compare it to the hash values
in the compromised database.

We can make a dictionary attack even more powerful by transforming the passwords in simple ways that
create additional educated guesses. For example, users will often make simple character substitutions--such as turning an `a` into an `@`
symbol, to comply with a system's password complexity requirements.

In this task, you will perform a dictionary attack that also attempts to transform its guesses. **Specifically, you will write a program that takes as its input a hash (remember, one generated with `cplhash.md5_hash()`) and the name of a file containing a list of words or passwords, each on its own line.** The words in this file are ordinary, non-transformed English words. Your program will use a single for-loop to guess each word or password twice: first in its non-transformed form and then second with all of the following characters substituted by your program:

* `@` for `a` and `A`
* `3` for `e` and `E`
* `1` for `i` and `I`
* `0` for `o` and `O`

For example, it would guess `tombrady` and then also `t0mbr@dy`. (`tombrady` is in file; your program will make the transformations necessary to generate `t0mbr@dy`.) Do all of the transformations at once, so don't separately test `t0mbrady` or `tombr@dy`. Your program should print a matching password and immediately exit if it finds a match, and print `No password found` if it fails to find a match.

(Note: the hashes below do not appear in bold, but they represent text the user inputs, not text your program should output.)

```
Hash to break: 1b3231655cebb7a1f783eddf27d254ca
Dictionary file: 𝘄𝗼𝗿𝗱𝘀.𝘁𝘅𝘁
super
```

```
Hash to break: 1cd30461f1450f450c4fc598afe5c6d5
Dictionary file: 𝘄𝗼𝗿𝗱𝘀.𝘁𝘅𝘁
sup3r
```

```
Hash to break: 63184a2e97244339cd4c5be1a2fd2a0e
Dictionary file: 𝘄𝗼𝗿𝗱𝘀.𝘁𝘅𝘁
b0wl
```

```
Hash to break: 6fd8a57fe4ac4adb8da6137b503250ed
Dictionary file: 𝘄𝗼𝗿𝗱𝘀.𝘁𝘅𝘁
No password found
```

If you want to find additional hashes you can use to test your code, just use the `cplhash.md5_hash()` function 
to generate hashes of passwords you know your program should find and passwords you know your program 
shouldn't find. Ensure your program behaves as expected. 

Task 3: brute_force.ipynb
----------------------

*This task is worth one-third of the total possible points (excluding style points).*

A *brute-force attack* is less clever than a dictionary attack. Rather than predict likely passwords, a brute-force
attack entails guessing every single possible password until it finds one that matches. This can be a very slow process,
however, so brute force attacks need to be confined to passwords matching a narrow constraint, such as passwords of a particular
length. 

Databases of breached passwords show that short, numeric passwords are
exceedingly popular. One explanation for this phenomenon is that
people tend to use birthdays as passwords. **Write a program that
takes a 32-character MD5 hash (i.e., a string generated using the
`cplhash.md5_hash()` function) as input and tries every possible six-digit
birthday (MMDDYY) to see which one was used to generate the hash.**

In other words, it should try all possible passwords of the form
`051689` (May 16th, '89). It should try all 12 months (single-digit
months like April should have two digits: `04`). It should try all
possible two-digit days (`01` through `31`). For the sake of
simplicity, pretend that every month has 31 days; in practice, your
program will make only 7 unnecessary guesses per year (February x3,
April, June, September November). It should try all 100 years (`00`
through `99`).

Your program should make its guesses using three nested for-loops (one each for months, days, and years), each using the `range()` function. If it finds
a password whose hash matches the user's input, it should print the password, stop guessing, and
immediately exit the program so as to avoid performing unnecessary work.
If it has tried every possible birthday and cannot find a match, it should print `No password found` and exit.


(Note: the hashes below do not appear in bold, but they represent text the user inputs, not text your program should output.)

```
Hash to break: ba36671fe7e883e660a543204e9c67d9
031469
```

```
Hash to break: 3e4fc29835685fa02b91b67451b0170a
122532
```

```
Hash to break: 56cf68f73da0248a1712f198d9c1e0d0
No password found
```

Once again, if you want to find additional hashes you can use to test your code, just use the `cplhash.md5_hash()` function 
to generate hashes of birthdate strings you know your program should find. Ensure your program behaves as expected.

*One style note:* It is considered bad style to use *magic numbers* like `12` and `31` directly in your code without
explanation; instead
you should save these values to variables at the top of your program just after any `import` statements
that you need. Since these values never change during the execution of the program, they are known as
*constants*. To distinguish constants from other variables, write their names in UPPERCASE_STYLE
(`MONTHS_PER_YEAR` and `DAYS_PER_MONTH`) and precede each constant with a comment explaining what it means.
You can then use these constant variables as necessary in your code.

***

Epilogue
========

You have now completed your whirlwind journey through the world of password-cracking. These methods represent
some of the most basic and effective tools in the password-cracking arsenal. In the wrong hands, they
can be used to harm others, but we hope that you have learned a slightly different lesson from this exercise.

Now that you have invested time learning how
attackers extract passwords from hashes, you are prepared to design password systems that resist attack.
* Researchers have discovered that they can manufacture hash collisions using md5, the hash function algorithm you used throughout
this problem set, thus rendering md5 unacceptably weak for production uses. Many websites have moved to using newer
algorithms that offer better collision resistance, with SHA-2 being a popular choice.
* Modern systems also use a method called *salting* that dramatically increases
the amount of work an attacker needs to break a database of hashes.
* You learned that short numeric passwords are weak and can be broken with brute-force attacks. This informs the
popular wisdom that passwords should be relatively long and contain a wide variety of characters (numbers, upper and lowercase
letters, and special characters).
* You learned that people tend to choose the same common passwords over and over again. If you were to design a website,
you could reject user passwords if they come from this list or are minor transformations of the passwords on this list.
* You learned that people tend to use words from the dictionary transformed in tiny ways, so you can reject these sorts of passwords
as well.

Although passwords remain an exceedingly popular way of authenticating users, many companies and researchers eagerly
await their demise.
* Passwords that are long and complicated enough to be secure are often hard to remember,
so users tend to choose weak passwords whenever possible. Users are also prone
to simply forgetting passwords, which is a major source of frustration.
* Managing passwords for the dozens of websites with which we interact verges on impossible. Users tend to reuse the same
passwords across multiple sites or keep spreadsheets (or even stickynotes) of passwords. These behaviors serve only to
make passwords even less secure.

With that said, passwords remain better than any proposed alternatives, so they unfortunately continue to be common
in practice. In recent years, several efforts have been made to improve or rehabilitate passwords and password management.
* In 2021, most websites do hash (and salt) their passwords. A few years ago, this was not the case.
* Modern smartphones substitute a password for a fingerprint or facial recognition. Since fingerprint readers are uncommon on laptops (and can sometimes be fooled), these techniques have not yet made it to full-sized computers.
* Many websites now use two-factor authentication, where you log in with both a password and a temporary code sent to your smartphone.
Doing so thwarts password-cracking by requiring both "something you know" (a password) and "something you have" (a smartphone).
* Password-managers like Lastpass are common ways of coping with the sheer number of different passwords that we deal with on a
daily basis. By eliminating the need to remember all of your passwords, password managers make it possible to use long, complicated,
hard-to-break passwords and to use different passwords on every single site. Security experts remain divided on whether password
managers improve security by making it easier to use longer passwords or hurt security but storing all of your passwords in one place.

Researchers are working hard to eliminate passwords entirely. One can only hope that, by the time your
children are in law school, passwords are as foreign to them as floppy disks are to you.

We hope that this problem set has been a valuable learning experience about both Python and passwords.

***

*This problem set was developed by Jonathan Frankle in 2017 and revised in 2018, 2019, 2020, and 2021 - &copy; 2021*

*In past years, Jonathan and Paul have engaged in snarky edit battles in this space debating whether Jonathan (proud Boston resident)
was prescient for including Tom Brady as an example for a problem set assigned around the time of the Super Bowl. Obviously, Paul has the upperhand this year
but with Brady fading into the sunset, this feels like a hollow victory.*