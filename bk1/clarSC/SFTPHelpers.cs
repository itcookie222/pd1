using System;
using System.Collections.Generic;
using System.Text;
using Scb.Framework;
using System.IO;

namespace Claris.Common
{
  public static class SFTPHelpers
  {
    public static void SendFile2SFTP(Chilkat.SFtp sftp, string hostname, int port,
     string user, string password, string filename)
    {
      try
      {
        bool success = false;
        string fileToOpen = "";

        sftp.ConnectTimeoutMs = 60000;
        sftp.IdleTimeoutMs = 60000;

        success = sftp.Connect(hostname, port);
        if (success != true)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        success = sftp.AuthenticatePw(user, password);
        if (success != true)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        success = sftp.InitializeSftp();
        if (success != true)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        string handle;
        handle = sftp.OpenDir(".");
        if (handle == null)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        Chilkat.SFtpDir dirListing = null;
        dirListing = sftp.ReadDir(handle);
        if (dirListing == null)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        int i;
        int n;
        n = dirListing.NumFilesAndDirs;
        if (n == 0)
        {
          Logger.Error("SendFile2SFTP::No entries found in this directory");
        }
        else
        {
          for (i = 0; i <= n - 1; i++)
          {
            Chilkat.SFtpFile fileObj = null;
            fileObj = dirListing.GetFileObject(i);

            fileToOpen = filename;
            if (fileObj.Filename == Path.GetFileName(filename))
            {
              fileToOpen = Path.GetFileNameWithoutExtension(filename) + "_" + DateTime.Now.Ticks.ToString() + Path.GetExtension(filename);
              break;
            }
          }
        }

        string filehandle = sftp.OpenFile(Path.GetFileName(fileToOpen), "writeOnly", "createNew");
        if (filehandle == null)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        success = sftp.UploadFile(filehandle, filename);
        if (success != true)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        success = sftp.CloseHandle(filehandle);
        if (success != true)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        success = sftp.CloseHandle(handle);
        if (success != true)
        {
          Logger.Error("SFTP::" + sftp.LastErrorText, null);
          return;
        }

        sftp.Disconnect();
      }
      catch (Exception ex)
      {
        Logger.Error("SendFile2SFTP::", ex);
        throw ex;
      }


    }

    public static string[] DownloadFromLocalFolder(string sourcePath, string destPath)
    {
      string[] fileList = null;
      string filename = null;
      try
      {

      }
      catch (Exception ex)
      {
        Logger.Error("DownloadFromLocalFolder::", ex);
      }
    }

    public static string[] DownloadFromSFTP(Chilkat.SFtp sftp, string hostname, int port,
      string user, string password, string sourcePath, string destPath)
    {

      string[] fileList = null;
      string filename = null;
      try
      {
        bool success = false;

        sftp.ConnectTimeoutMs = 60000;
        sftp.IdleTimeoutMs = 60000;

        success = sftp.Connect(hostname, port);
        if (success != true)
        {
          Logger.Error("SFTP::Connect" + sftp.LastErrorText, null);
          Helpers.NotifyEmail(String.Format("SFTP::Connect::Host::{0}::{1}", hostname, sftp.LastErrorText));
          return null;
        }

        success = sftp.AuthenticatePw(user, password);
        if (success != true)
        {
          Logger.Error("SFTP::AuthenticatePw" + sftp.LastErrorText, null);
          return null;
        }

        success = sftp.InitializeSftp();
        if (success != true)
        {
          Logger.Error("SFTP::InitializeSftp" + sftp.LastErrorText, null);
          return null;
        }

        string handle;
        handle = sftp.OpenDir(sourcePath);
        if (handle == null)
        {
          Logger.Error("SFTP::OpenDir" + sftp.LastErrorText, null);
          return null;
        }

        Chilkat.SFtpDir dirListing = null;
        dirListing = sftp.ReadDir(handle);
        if (dirListing == null)
        {
          Logger.Error("SFTP::ReadDir" + sftp.LastErrorText, null);
          return null;
        }

        //Iterate over the files.
        int i;
        int n;
        n = dirListing.NumFilesAndDirs;
        fileList = new string[n];
        if (n == 0)
        {
          Logger.Error("DownloadFromSFTP::No entries found in this directory");
        }
        else
        {
          for (i = 0; i <= n - 1; i++)
          {
            Chilkat.SFtpFile fileObj = null;
            fileObj = dirListing.GetFileObject(i);

            if (fileObj.FileType == "directory")
              continue;

            string filehandle = sftp.OpenFile(sourcePath + "/" + fileObj.Filename, "readOnly", "openExisting");

            if (filehandle == null)
            {
              Logger.Error("SFTP::" + sftp.LastErrorText, null);
              filename = "";
            }
            filename = Path.Combine(destPath, Path.GetFileName(fileObj.Filename));

            success = sftp.DownloadFile(filehandle, filename);
            if (success != true)
            {
              Logger.Error("SFTP::DownloadFile" + sftp.LastErrorText, null);
            }
            else
            {
              success = sftp.CloseHandle(filehandle);
              if (success != true)
              {
                Logger.Error("SFTP::CloseHandle" + sftp.LastErrorText, null);
              }

              success = sftp.RemoveFile(sourcePath + "/" + fileObj.Filename);
              if (success != true)
              {
                Logger.Error("SFTP::RemoveFile" + sftp.LastErrorText, null);
              }

              fileList[i] = filename;
            }
          }
        }

        success = sftp.CloseHandle(handle);
        if (success != true)
        {
          Logger.Error("SFTP::CloseHandle" + sftp.LastErrorText, null);
          return null;
        }

        sftp.Disconnect();

        return fileList;
      }
      catch (Exception ex)
      {
        Logger.Error("SendFile2SFTP::", ex);
        throw ex;
      }
    }
  }
}
