import re
from collections import Counter

s = open('lib/l10n/translations.dart').read()
ks = re.findall(r'^  ("[^"]*"|\'(?:[^\'\\]|\\.)*\')\s*:', s, re.M)


def norm(k):
    return k[1:-1].replace("\\'", "'").replace('\\"', '"')


names = [norm(k) for k in ks]
print('dup:', [k for k, c in Counter(names).items() if c > 1])
