module ScanAllFiles(getStruct,
                    unwantedPath,
                    accessAllowed,
                    manageDirectory,
                    listAllFiles
                  )
where

import System.Directory 
import System.Posix
import Control.Monad
import System.Environment
import Data.List
import qualified Data.Set as S 
import System.IO
import Control.Exception
import System.Posix.Time

-- useless 
eliminateDuplicates :: (Ord a) => [a] -> [a]
eliminateDuplicates = go S.empty
  where go _ [] = []
        go s (x:xs) | S.member x s = go s xs
                    | otherwise    = x : go (S.insert x s) xs

getStruct :: [FilePath] -> IO [(FilePath, Integer, System.Posix.EpochTime)]
getStruct [] =  return []
getStruct (f:fs) = do
          -- Ultimate verification: trying to open the file & get his size
          sizeFile <-  try (withFile f ReadMode $ \h -> do hFileSize h >>= return) :: IO (Either SomeException Integer)
          case sizeFile of
              Left ex  -> getStruct fs >>= return
              Right sizeFile -> go sizeFile
                where 
                  go sizeFile = do
                      status <- getFileStatus f
                      let aTime = accessTime status
                      recursiveStruct <- (getStruct fs)
                      return ((f,sizeFile,aTime) : recursiveStruct)

unwantedPath :: [FilePath]
unwantedPath = ["//Network",
                "//dev",
                "//Volumes"]

accessAllowed :: FilePath ->IO Bool
accessAllowed path = 
      if (path `elem` unwantedPath) then 
          return False
      else do
          status <- getFileStatus path
          doesFileExists <- fileExist path
          isAccessPermitted <- getPermissions path 
          return  (doesFileExists && (readable isAccessPermitted))

manageDirectory :: FilePath -> DirStream -> String -> IO [FilePath]
manageDirectory _ dir []  = closeDirStream dir >>= \_ -> return []
manageDirectory path dir "." = readDirStream dir >>= manageDirectory path dir
manageDirectory path dir ".."= readDirStream dir >>= manageDirectory path dir
manageDirectory path dir file= 
                    let newpath = path++"/"++file in do
                      allFiles <- listAllFiles newpath
                      allFiles' <- readDirStream dir >>= manageDirectory path dir
                      return (allFiles++allFiles')

listAllFiles :: FilePath -> IO [FilePath]
listAllFiles path = do
      isAccessAllowed <- try (accessAllowed path) :: IO (Either SomeException Bool)
      case isAccessAllowed of
        Left ex  -> return []
        Right allowed -> go path allowed
          where 
            go path True = do
              file <- getSymbolicLinkStatus path
              if isDirectory file then do
                 dir <- openDirStream path
                 allFiles <- readDirStream dir >>= manageDirectory path dir
                 return allFiles
              else do
                return [path]
            go _ _ = return []
