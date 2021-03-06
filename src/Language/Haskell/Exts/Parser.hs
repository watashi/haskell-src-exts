{-# LANGUAGE DeriveDataTypeable, FlexibleInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Language.Haskell.Exts.Parser
-- Copyright   :  (c) The GHC Team, 1997-2000
--                (c) Niklas Broberg, 2004-2012
-- License     :  BSD-style (see the file LICENSE.txt)
--
-- Maintainer  :  Niklas Broberg, niklas.broberg@chalmers.se
-- Stability   :  stable
-- Portability :  portable
--
-- Parser for Haskell with extensions.
--
-----------------------------------------------------------------------------

module Language.Haskell.Exts.Parser
            (
                -- * General parsing
                Parseable(parse, parseWithMode, parseWithComments),
                ParseMode(..), defaultParseMode, ParseResult(..), fromParseResult,
                -- * Parsing of specific AST elements
                -- ** Modules
                parseModule, parseModuleWithMode, parseModuleWithComments,
                -- ** Expressions
                parseExp, parseExpWithMode, parseExpWithComments,
                -- ** Statements
                parseStmt, parseStmtWithMode, parseStmtWithComments,
                -- ** Patterns
                parsePat, parsePatWithMode, parsePatWithComments,
                -- ** Declarations
                parseDecl, parseDeclWithMode, parseDeclWithComments,
                -- ** Types
                parseType, parseTypeWithMode, parseTypeWithComments,
                -- ** Import declarations
                parseImportDecl, parseImportDeclWithMode,
                parseImportDeclWithComments,
                -- * Non-greedy parsers
                NonGreedy(..),
                -- ** Module head parsers
                getTopPragmas,
                PragmasAndModuleName(..),
                PragmasAndModuleHead(..),
                ModuleHeadAndImports(..)
            ) where

import           Data.Data (Data, Typeable)
import           Language.Haskell.Exts.Annotated.Fixity
import           Language.Haskell.Exts.Annotated.Parser (unListOf, ListOf, NonGreedy(..))
import qualified Language.Haskell.Exts.Annotated.Parser as A
import           Language.Haskell.Exts.Annotated.Simplify
import           Language.Haskell.Exts.Annotated.Syntax
import           Language.Haskell.Exts.Comments
import           Language.Haskell.Exts.ParseMonad hiding (getModuleName)
import           Language.Haskell.Exts.SrcLoc
import qualified Language.Haskell.Exts.Syntax as S

parseWithSimplify :: Parseable a => a -> (a -> a') -> Maybe [Fixity] -> P a'
parseWithSimplify _witness simpl mfixs = parser mfixs >>= return . simpl

instance Parseable S.Decl   where parser = parseWithSimplify (undefined :: Decl   SrcSpanInfo) sDecl
instance Parseable S.Exp    where parser = parseWithSimplify (undefined :: Exp    SrcSpanInfo) sExp
instance Parseable S.Module where parser = parseWithSimplify (undefined :: Module SrcSpanInfo) sModule
instance Parseable S.Pat    where parser = parseWithSimplify (undefined :: Pat    SrcSpanInfo) sPat
instance Parseable S.Stmt   where parser = parseWithSimplify (undefined :: Stmt   SrcSpanInfo) sStmt
instance Parseable S.Type   where parser = parseWithSimplify (undefined :: Type   SrcSpanInfo) sType
instance Parseable S.ImportDecl where parser = parseWithSimplify (undefined :: ImportDecl SrcSpanInfo) sImportDecl

instance Parseable (NonGreedy [S.ModulePragma]) where
  parser = parseWithSimplify
    (undefined :: NonGreedy (ListOf (ModulePragma SrcSpanInfo)))
    (fmap (map sModulePragma . unListOf))

-- Type-specific functions

-- | Parse of a string, which should contain a complete Haskell module, using 'defaultParseMode'.
parseModule :: String -> ParseResult S.Module
parseModule = parse

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode'.
parseModuleWithMode :: ParseMode -> String -> ParseResult S.Module
parseModuleWithMode = parseWithMode

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode', retaining comments.
parseModuleWithComments :: ParseMode -> String -> ParseResult (S.Module, [Comment])
parseModuleWithComments = parseWithComments

-- | Parse of a string containing a Haskell expression, using 'defaultParseMode'.
parseExp :: String -> ParseResult S.Exp
parseExp = parse

-- | Parse of a string containing a Haskell expression, using an explicit 'ParseMode'.
parseExpWithMode :: ParseMode -> String -> ParseResult S.Exp
parseExpWithMode = parseWithMode

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode', retaining comments.
parseExpWithComments :: ParseMode -> String -> ParseResult (S.Exp, [Comment])
parseExpWithComments = parseWithComments

-- | Parse of a string containing a Haskell pattern, using 'defaultParseMode'.
parsePat :: String -> ParseResult S.Pat
parsePat = parse

-- | Parse of a string containing a Haskell pattern, using an explicit 'ParseMode'.
parsePatWithMode :: ParseMode -> String -> ParseResult S.Pat
parsePatWithMode = parseWithMode

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode', retaining comments.
parsePatWithComments :: ParseMode -> String -> ParseResult (S.Pat, [Comment])
parsePatWithComments = parseWithComments

-- | Parse of a string containing a Haskell top-level declaration, using 'defaultParseMode'
parseDecl :: String -> ParseResult S.Decl
parseDecl = parse

-- | Parse of a string containing a Haskell top-level declaration, using an explicit 'ParseMode'.
parseDeclWithMode :: ParseMode -> String -> ParseResult S.Decl
parseDeclWithMode = parseWithMode

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode', retaining comments.
parseDeclWithComments :: ParseMode -> String -> ParseResult (S.Decl, [Comment])
parseDeclWithComments = parseWithComments

-- | Parse of a string containing a Haskell type, using 'defaultParseMode'.
parseType :: String -> ParseResult S.Type
parseType = parse

-- | Parse of a string containing a Haskell type, using an explicit 'ParseMode'.
parseTypeWithMode :: ParseMode -> String -> ParseResult  S.Type
parseTypeWithMode = parseWithMode

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode', retaining comments.
parseTypeWithComments :: ParseMode -> String -> ParseResult (S.Type, [Comment])
parseTypeWithComments = parseWithComments

-- | Parse of a string containing a Haskell type, using 'defaultParseMode'.
parseStmt :: String -> ParseResult S.Stmt
parseStmt = parse

-- | Parse of a string containing a Haskell type, using an explicit 'ParseMode'.
parseStmtWithMode :: ParseMode -> String -> ParseResult S.Stmt
parseStmtWithMode = parseWithMode

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode', retaining comments.
parseStmtWithComments :: ParseMode -> String -> ParseResult (S.Stmt, [Comment])
parseStmtWithComments = parseWithComments

-- | Parse of a string containing a Haskell import declaration, using 'defaultParseMode'.
parseImportDecl :: String -> ParseResult S.ImportDecl
parseImportDecl = parse

-- | Parse of a string containing a Haskell type, using an explicit 'ParseMode'.
parseImportDeclWithMode :: ParseMode -> String -> ParseResult S.ImportDecl
parseImportDeclWithMode = parseWithMode

-- | Parse of a string containing a complete Haskell module, using an explicit 'ParseMode', retaining comments.
parseImportDeclWithComments :: ParseMode -> String -> ParseResult (S.ImportDecl, [Comment])
parseImportDeclWithComments = parseWithComments



-- Module head parsers

-- | Partial parse of a string starting with a series of top-level option pragmas.
getTopPragmas :: String -> ParseResult [S.ModulePragma]
getTopPragmas = fmap (fmap unNonGreedy) parse

-- | Type intended to be used with 'Parseable', with instances that
--   implement a non-greedy parse of the module name, including
--   top-level pragmas.  This means that a parse error that comes
--   after the module header won't be returned. If no module name is
--   found (and no parse error occurs), then \"Main\" is returned.
--   This is the same behavior that 'parseModule' has.
data PragmasAndModuleName = PragmasAndModuleName
    [S.ModulePragma]
    S.ModuleName
  deriving (Eq,Ord,Show,Typeable,Data)

instance Parseable (NonGreedy PragmasAndModuleName) where
    parser fixs = do
        NonGreedy (A.PragmasAndModuleName _ ps mmn) <- parser fixs
        return $ NonGreedy $ PragmasAndModuleName
            (map sModulePragma (ps :: [ModulePragma SrcSpanInfo]))
            (maybe S.main_mod sModuleName mmn)

-- | Type intended to be used with 'Parseable', with instances that
--   implement a non-greedy parse of the module name, including
--   top-level pragmas.  This means that a parse error that comes
--   after the module header won't be returned. If no module head is
--   found, then a default simple head like \"module Main where\" is
--   assumed. This is the same behavior that 'parseModule' has.
--
--   Note that the 'ParseMode' particularly matters for this due to
--   the 'MagicHash' changing the lexing of identifiers to include
--   \"#\".
data PragmasAndModuleHead = PragmasAndModuleHead
    [S.ModulePragma]
    (S.ModuleName, Maybe S.WarningText, Maybe [S.ExportSpec])
  deriving (Eq,Ord,Show,Typeable,Data)

instance Parseable (NonGreedy PragmasAndModuleHead) where
    parser fixs = do
        NonGreedy (A.PragmasAndModuleHead _ ps mmh) <- parser fixs
        return $ NonGreedy $ PragmasAndModuleHead
            (map sModulePragma (ps :: [ModulePragma SrcSpanInfo]))
            (sModuleHead mmh)

-- | Type intended to be used with 'Parseable', with instances that
--   implement a non-greedy parse of the module head, including
--   top-level pragmas, module name, export list, and import
--   list. This means that if a parse error that comes after the
--   imports won't be returned.  If no module head is found, then a
--   default simple head like \"module Main where\" is assumed. This
--   is the same behavior that 'parseModule' has.
--
--   Note that the 'ParseMode' particularly matters for this due to
--   the 'MagicHash' changing the lexing of identifiers to include
--   \"#\".
data ModuleHeadAndImports = ModuleHeadAndImports
    [S.ModulePragma]
    (S.ModuleName, Maybe S.WarningText, Maybe [S.ExportSpec])
    [S.ImportDecl]
  deriving (Eq,Ord,Show,Typeable,Data)

instance Parseable (NonGreedy ModuleHeadAndImports) where
    parser fixs = do
        NonGreedy (A.ModuleHeadAndImports _ ps mmh imps) <- parser fixs
        return $ NonGreedy $ ModuleHeadAndImports
            (map sModulePragma (ps :: [ModulePragma SrcSpanInfo]))
            (sModuleHead mmh)
            (map sImportDecl imps)
