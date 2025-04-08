import { createSignal, Match, Show, Switch, type JSX } from 'solid-js'
import { debounce, getFileSize } from '@/core/lib/utils'
import { downloadFile, shareFile } from '@/core/controllers/archivos'
import { AndroidIcon } from '@/components/solidjs/icons/AndroidIcon'
import { DownloadIcon } from '@/components/solidjs/icons/DownloadIcon'
import { WindowsIcon } from '@/components/solidjs/icons/WindowsIcon'
import { TrashIcon } from '@/components/solidjs/icons/TrashIcon'
import { LoadingIcon } from '@/components/solidjs/icons/LoadingIcon'
import type { FileEntity } from '@/types/archivos'
import { QuestionMarkCircleIcon } from './icons/QuestionMarkCircleIcon'
import { fileTypeValues } from '@/core/consts'
import { ShareIcon } from './icons/ShareIcon'

interface Props {
  file: FileEntity
  deleteItem: () => void
  shareFile: () => void
}

const CardButton = (props: JSX.ButtonHTMLAttributes<HTMLButtonElement>) => {
  return (
    <button
      class="border border-white/10 p-1.5 rounded text-gray-400 hover:not-disabled:bg-white/10 hover:not-disabled:text-white transition-colors w-fit h-fit"
      {...props}
    >
      {props.children}
    </button>
  )
}

export const FileCard = ({ file, deleteItem, shareFile }: Props) => {
  const [confirmVisible, setConfirmVisible] = createSignal(false)
  const [message, setMessage] = createSignal('')
  const [downloading, setDownloading] = createSignal(false)

  const debounceSetMessage = debounce(setMessage, 3000)
  const updateMessage = (value: string) => {
    setMessage(value)
    debounceSetMessage('')
  }

  const handleClickDelete = () => {
    if (confirmVisible()) {
      deleteItem()
      setConfirmVisible(false)
    } else {
      setConfirmVisible(true)
    }
  }

  const handleDownloadClick = async () => {
    if (downloading()) {
      return
    }

    setDownloading(true)
    updateMessage('')
    const { data, error } = await downloadFile({
      filename: file.filename
    })
    setDownloading(false)

    if (error != null) {
      updateMessage(error.message)
      return
    }

    updateMessage(data.message)
  }

  return (
    <div
      class={`rounded shadow p-3 text-sm space-y-2 transition-colors border
            text-gray-300 bg-black/20 border-white/10
            ${
              downloading()
                ? 'bg-black/30 border-white/20'
                : 'bg-black/20 border-white/10 hover:bg-black/30 hover:border-white/20'
            }`}
    >
      <Show when={downloading()}>
        <div class="flex flex-wrap items-center gap-2">
          <span class="font-medium text-white">Descargando archivo</span>
          <LoadingIcon class="w-4 h-4 animate-spin" />
        </div>
      </Show>
      <Show when={message().length > 0}>
        <p class="font-medium text-cyan-300">{message()}</p>
      </Show>

      <div class="flex flex-wrap gap-2">
        <Switch
          fallback={
            <span class="bg-gray-500/10 p-2 inline-block rounded border border-gray-600">
              <QuestionMarkCircleIcon class="w-6 h-6 text-gray-300" />
            </span>
          }
        >
          <Match when={file.tipo === fileTypeValues.apk}>
            <span class="bg-emerald-500/10 p-2 inline-block rounded border border-emerald-900">
              <AndroidIcon class="w-6 h-6" />
            </span>
          </Match>
          <Match when={file.tipo === fileTypeValues.desktopApp}>
            <span class="bg-cyan-500/15 p-2 inline-block rounded border border-cyan-900">
              <WindowsIcon class="w-6 h-6" />
            </span>
          </Match>
        </Switch>
        <div>
          <div>
            <span class="text-gray-200 font-semibold">
              <Switch fallback={'Desconocido'}>
                <Match when={file.tipo === fileTypeValues.apk}>
                  Android App
                </Match>
                <Match when={file.tipo === fileTypeValues.desktopApp}>
                  Aplicación para Windows
                </Match>
              </Switch>
            </span>
          </div>
          <div>
            <span class="text-gray-500 mr-1">Tamaño:</span>
            <span>{getFileSize(Number(file.size))}</span>
          </div>
        </div>
      </div>

      <div>
        <p class="text-gray-500 block">Nombre:</p>
        <p class="overflow-hidden overflow-ellipsis">{file.nombre}</p>
      </div>
      <div>
        <p class="text-gray-500 block">Archivo:</p>
        <p class="overflow-hidden overflow-ellipsis">{file.filename}</p>
      </div>
      <div>
        <p class="text-gray-500 block">Version:</p>
        <p class="overflow-hidden overflow-ellipsis">{file.version}</p>
      </div>
      <div>
        <p class="text-gray-500 block">Subido:</p>
        <p class="overflow-hidden overflow-ellipsis">
          {new Date(file.fechaCreacion).toLocaleString()}
        </p>
      </div>
      <div>
        <p class="text-gray-500 block">Autor:</p>
        <p>{file.user?.nombre ?? 'Desconocido'}</p>
      </div>
      <div class="flex flex-wrap gap-2 justify-end">
        <div class="flex mr-auto gap-2">
          <CardButton
            class={`border border-white/10 p-1.5 rounded
          hover:not-disabled:bg-white/10
            flex gap-1
            transition-colors
            ${
              confirmVisible()
                ? 'hover:text-red-400 z-50 text-white'
                : 'text-gray-400 hover:not-disabled:text-white'
            }`}
            disabled={downloading()}
            onclick={handleClickDelete}
          >
            <TrashIcon class="w-5 h-5" />
            <Show when={confirmVisible()}>
              <span class="text-sm font-medium">Eliminar</span>
            </Show>
          </CardButton>
          <Show when={confirmVisible()}>
            <div
              class="inset-0 bg-black/30 fixed z-10"
              onclick={() => {
                setConfirmVisible(false)
              }}
            ></div>
            <button
              class={`border border-white/10 p-1.5 rounded text-white
              hover:bg-white/10 hover:text-green-400 z-50
              transition-colors`}
              onclick={() => {
                setConfirmVisible(false)
              }}
            >
              <span class="text-sm font-medium">Conservar</span>
            </button>
          </Show>
        </div>
        <CardButton disabled={downloading()} onclick={handleDownloadClick}>
          <DownloadIcon class="w-5 h-5" />
        </CardButton>
        <CardButton
          onclick={() => {
            shareFile()
          }}
        >
          <ShareIcon class="w-5 h-5" />
        </CardButton>
      </div>
    </div>
  )
}
