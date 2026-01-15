import math
N = 16
d = 100

# choose_multiplier
def choose_multiplier(d, N):
    l = math.ceil(math.log2(d))
    sh_post = l
    m_low = math.floor( (2 ** (N + l)) / d )
    m_high = math.floor( (2**(N+l) + 2**(l))/d )
    while m_low // 2 < m_high // 2 and sh_post > 0:
        m_low = m_low // 2
        m_high = m_high // 2
        sh_post = sh_post - 1

    # print(f"({m_high}, {sh_post}, {l})")
    return (m_high, sh_post, l)

m, sh_post, l = choose_multiplier(d, N)
if m>=2**N and d % 2 == 0:
    e = int(math.log2(d & 2**N - d))
    sh_pre = e
    m, sh_post, l_dummy = choose_multiplier(100 / (2**e), N - e)

if (m >= 2**N):
    raise RuntimeError("Not implemented for this case!")

check = True
for i in range(2**(10)):
    q = (m * (i >> sh_pre)) >> N-e >> sh_post
    r = i - (q * 100)
    if (q != i // 100) or (r != i % 100):
        check = False
        print(f"Mismatch at n = {i}, got ({q}, {r}) != ({i//100}, {i%100})")

if(check):
    print("SUCCESS: Brute force validation passed")
    print(f"Run-time invariants (N, d, m, e, sh_pre, sh_post) = ({N}, {d}, {m}, {e}, {sh_pre}, {sh_post})")
    print("q = (m * (n >> sh_pre)) >> (N-e) >> sh_post")

else:
    print("FAIL: Check mismatch above")