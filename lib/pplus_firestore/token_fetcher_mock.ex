defmodule PPlusFireStore.TokenFetcherMock do
  @moduledoc false
  use PPlusFireStore.TokenFetcher

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    {:ok, []}
  end

  def fetch(_module) do
    {:ok,
     %{
       token:
         "ya29.c.c0ASRK0Ga9zUcnYHmC3hf3BRS55wiPtPGVldBnu2Er5VCtS0x4uBz71jkpd77JNPXeddyEVkavX2UzsheTyn3sibnxZgkNSzl2V09oeEx_pmzSERXGBaLD0R_GD7ITKYKlQ-Qd-7fXu00A4I60rhB_z7mZ5Vd1T6on2ZJ4bf3OfBF54_iztwsfVVsaqOf8Qwsda699JyxZwVTRe2KtppXXMmtm7tF3TSz6cNw09FGI1dgxb4Fe8yA4e3gDCEZC2IbPQLfJfRt2hR9Ly9eDVOR9u2xkHerTFgDvi67wmZ5ldJjjxOd6ndkWPK4LONIXIXzfgjrl0JUgbQAefyvW86K4q3SZVu_moTBQDnZlOzk4WZB03AekFsZGUSM-E385P34yfiV1I_ot9l5BQggS7-5JrxwtBqt10z5M4h6r4gpI-UW8ZcQihk7ykpjuX2sWwuqcWJ16Jqlaq3-Qz2Rltf3m9r22ufIubIk_Oj_xMIWltmsUIlxqv00UfWdldrV-Buo4Mk8fb9o9XQJF6sj6UUd3l3co-QlRrsyiXViisSyi25qMSxc56lBw0XlBhSqW4-a-4nmovVIfbcih2mbe1kIiqUj3VytiY6cX3rcOl03n_RvX2421ukthmOhIuon4BY5_0V0Q6ad9_QmwyOjwkQksqp8_4JSBOw-qXrlfX0B3JZ03Z6emzhn2BpuOo75wfdhZv_fUn4sp4a-gsJ2l4Os2WMJjt87lq7hUrMg3tgUqJbR8VUoFFM-yB_kmvrkcclu7U4dvBvoJ9Fvno4SfhXbz9awt-RdUJRpOO2brgFvXdzie1lqiwSMrXu0Bw2aMvqnphtnbfSzpriX5miMM1VwMMXwcd1jXa7URrzB6BVv231_135r3_SzMw6-Yc315ft_bMa-2Bn85-eZnVR5oyR9Xmq7dII-idiwx7ohXJVd9mmfJd67kj1tQMjBokv1VJu6anmozcs4h5Sei1Zuqlp5bISIBi5X0_5xfgi2untU3cbMJx1kQwF9bQ-v"
     }}
  end
end
