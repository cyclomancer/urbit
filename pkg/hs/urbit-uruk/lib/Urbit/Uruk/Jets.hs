{-
   DONE Numberic jets are not matched, and therefore not evaluated in
        jet dashboard. What do?
   DONE Need to handle data jets too.
-}

module Urbit.Uruk.Jets where

import ClassyPrelude

import Data.List             (iterate, (!!))
import Numeric.Natural       (Natural)
import Urbit.Uruk.DashParser (DataJet(..), ExpTree(..), Pos, SingJet(..),
                              Ur(..), Val)

import qualified Urbit.Atom            as Atom
import qualified Urbit.Uruk.DashParser as Dash


-- Utils -----------------------------------------------------------------------

pattern NS = N S
pattern NK = N K
pattern NJ = N J
pattern ND = N D
pattern NB = N (SingJet BEE)
pattern NC = N (SingJet SEA)

jn :: Pos -> Val
jn 1 = N J
jn n = jn (n-1) :& N J


--------------------------------------------------------------------------------

djArity :: DataJet -> Pos
djArity (NAT _) = 2
djArity (Sn n)  = 2 + n
djArity (Bn n)  = 2 + n
djArity (Cn n)  = 2 + n

sjArity :: SingJet -> Pos
sjArity = $(pure Dash.jetArity)

jetArity :: Either DataJet SingJet -> Pos
jetArity = either djArity sjArity


--------------------------------------------------------------------------------

sjTag :: SingJet -> Val
sjTag = $(pure Dash.jetTag)

djTag (NAT _) = N K
djTag (Sn _)  = N (DataJet $ NAT $ Atom.utf8Atom "sn")
djTag (Bn _)  = N (DataJet $ NAT $ Atom.utf8Atom "bn")
djTag (Cn _)  = N (DataJet $ NAT $ Atom.utf8Atom "cn")

jetTag :: Either DataJet SingJet -> Val
jetTag = either djTag sjTag


--------------------------------------------------------------------------------

sjBody :: SingJet -> Val
sjBody = $(pure Dash.jetBody)

skSucc :: Val
skSucc = NS :& (NS :& (NK :& NS) :& NK)

djBody :: DataJet -> Val
djBody = \case
  NAT 0 -> NS :& NK
  NAT n -> skSucc :& djBody (NAT $ pred n)
  Sn  n -> iterate (NB :& (NB :& NS) :& NB :&) NS !! (fromIntegral n - 1)
  Bn  n -> iterate (NB :& NB :&)               NB !! (fromIntegral n - 1)
  Cn  n -> iterate (NB :& (NB :& NC) :& NB :&) NC !! (fromIntegral n - 1)

jetBody :: Either DataJet SingJet -> Val
jetBody = either djBody sjBody


--------------------------------------------------------------------------------

sjTuple :: SingJet -> (Pos, Val, Val)
sjTuple sj = (sjArity sj, sjTag sj, sjBody sj)

djTuple :: DataJet -> (Pos, Val, Val)
djTuple sj = (djArity sj, djTag sj, djBody sj)

jetTuple :: Either DataJet SingJet -> (Pos, Val, Val)
jetTuple jet = (jetArity jet, jetTag jet, jetBody jet)


--------------------------------------------------------------------------------

sjMatch :: (Pos, Val, Val) -> Maybe SingJet
sjMatch = $(pure Dash.jetMatch)

natMatch :: Val -> Maybe Natural
natMatch (NS :& NK) = pure 0
natMatch (NS :& (NS :& (NK :& NS) :& NK) :& n) = succ <$> natMatch n
natMatch _ = Nothing

snMatch :: Val -> Maybe Pos
snMatch NS                            = Just 1
snMatch (NB :& (NB :& NS) :& NB :& r) = succ <$> snMatch r
snMatch _                             = Nothing

bnMatch :: Val -> Maybe Pos
bnMatch NB              = Just 1
bnMatch (NB :& NB :& n) = succ <$> bnMatch n
bnMatch _               = Nothing

cnMatch :: Val -> Maybe Pos
cnMatch NC                            = Just 1
cnMatch (NB :& (NB :& NC) :& NB :& n) = succ <$> cnMatch n
cnMatch _                             = Nothing

pattern SnTag = N (DataJet (NAT 28275))
pattern BnTag = N (DataJet (NAT 28258))
pattern CnTag = N (DataJet (NAT 28259))

djMatch :: (Pos, Val, Val) -> Maybe DataJet
djMatch (2, N K, natMatch -> Just n) = Just (NAT n)
djMatch (r, SnTag, snMatch -> Just p) | r == p + 2 = Just (Sn p)
djMatch (r, BnTag, bnMatch -> Just p) | r == p + 2 = Just (Bn p)
djMatch (r, CnTag, cnMatch -> Just p) | r == p + 2 = Just (Cn p)
djMatch _                            = Nothing

jetMatch :: (Pos, Val, Val) -> Maybe (Either DataJet SingJet)
jetMatch tup = (Right <$> sjMatch tup) <|> (Left <$> djMatch tup)


--------------------------------------------------------------------------------

sjUnMatch :: SingJet -> Val
sjUnMatch sj = jn ari :& tag :& bod
 where
  (ari, tag, bod) = sjTuple sj

djUnMatch :: DataJet -> Val
djUnMatch sj = jn ari :& tag :& bod
 where
  (ari, tag, bod) = djTuple sj

jetUnMatch :: Either DataJet SingJet -> Val
jetUnMatch jet = jn ari :& tag :& bod
 where
  (ari, tag, bod) = jetTuple jet
